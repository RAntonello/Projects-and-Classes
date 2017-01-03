import os
import json
import uuid
import urllib
import cPickle as pickle
import datetime
import shutil
import random
import copy

import numpy as np
from scipy.misc import imread

from visipedia.utils.command_line import print_progress

class Dataset(object):
	
	def __init__(self, image_cache, data_cache):
		"""
		This just stores the image cache and data cache paths
		"""
		self.image_cache = image_cache # this is where will we store the images
		self.data_cache = data_cache # this is where we will store feature data, classifier data, etc.
		
		self.vibe_file_path = os.path.join(self.data_cache, 'vibe_file.json')
		self.image_split_path = os.path.join(self.data_cache, 'image_split.json')
		
	def bootup(self, vibe_file_path = None):
		"""
		This will either use the specified vibe file path, or search for the vibe file in the data cache, and
		then will initialize the category and image data structures. 
		"""
		
		# If the user gives us a vibe file then move into our data cache. We will reuse it on future boots
		if vibe_file_path != None:
			
			if not os.path.exists(vibe_file_path):
				print "The specified vibe file path does not exist"
				raise RuntimeError
			
			moved_file_path = self.vibe_file_path#os.path.join(self.data_cache, 'vibe_file.json')
			
			# as a sanity check, lets see if we already have a vibe file in our data cache
			if os.path.exists(moved_file_path):
				#print "A vibe file already exists in our data cache. You need to manually remove it."
				#raise RuntimeError
				pass
				
			# has the user already renamed it and put it in the right spot? 
			if os.path.relpath(moved_file_path) != os.path.relpath(vibe_file_path):
				shutil.copyfile(vibe_file_path, moved_file_path)

		#vibe_file_path = os.path.join(self.data_cache, 'vibe_file.json')
		assert os.path.exists(self.vibe_file_path), "Could not locate vibe_file.json in the data cache."
		
		with open(self.vibe_file_path) as f:
			vibe_data = json.load(f)
		
		# default initialization
		self.training_images = None
		self.testing_images = None
		
		# Process the buckets
		buckets = vibe_data['buckets']
		self.name = buckets['name']
		for child in buckets['children']:
			
			# we are looking for specific children here
			child_name = child['name']
			
			if child_name.lower() == 'hierarchy':
				print "Found Hierarchy bucket, processing it now..."
				self.category_root = Category(child, self)
				self.raw_category_hierarchy = child
				
			if child_name.lower() == 'split':
				print "Found Split bucket, processing it now..."
				self.process_split(child)
			
		# Store the image data for later use
		self.image_data = vibe_data['uuid_map']	
		self.image_url_prefix = vibe_data['url_prefix']
		
		if 'resized_data' in vibe_data and 'size_data' in vibe_data:
			self.process_resized_image_data(vibe_data['resized_data'], vibe_data['size_data'])
		else:
			self.resized_image_data = None
			self.size_data = None
		
		# this will hold a pointer to categories in the hierarchy (just a convenience so that we don't have to search for a category each time)
		self.category_cache = {}
		
		# have we already defined a training / testing split? Load it in if so:
		# this will override the split in the snapshot
		if os.path.exists(self.image_split_path):
			print "Loading in existing train / test split file"
			with open(self.image_split_path) as f:
				image_split_data = json.load(f)
			
			self.training_images = image_split_data['train']
			self.testing_images = image_split_data['test']
			
		
	@property
	def image_cache(self):
		return self._image_cache
	@image_cache.setter
	def image_cache(self, path):
		# create the directory if it does not exist
		if not os.path.exists(path):
			os.makedirs(path)
		self._image_cache = path
		
		# create a `photos` directory in the image cache directory
		photos_dir_path = os.path.join(self._image_cache, 'photos')
		if not os.path.exists(photos_dir_path):
			os.makedirs(photos_dir_path)	
	
	@property
	def data_cache(self):
		return self._data_cache
	@data_cache.setter
	def data_cache(self, path):
		if not os.path.exists(path):
			os.makedirs(path)
		self._data_cache = path
		
		# set up the feature directory
		feature_dir = os.path.join(self.data_cache, 'features')
		if not os.path.exists(feature_dir):
			os.makedirs(feature_dir)
		self.feature_dir = feature_dir
	
	def process_resized_image_data(self, resized_data, size_data):
		
		resized_image_data = {}
		resized_sizes = {}
		for data in resized_data:
			try:
				image_id, image_path, size_id, width, height = data
				resized_sizes.setdefault(image_id, {})[size_id] = (width, height)
			except:
				image_id, image_path, size_id = data
			
			resized_image_data.setdefault(image_id, {})[size_id] = image_path
		
		self.resized_image_data = resized_image_data
		self.size_data = size_data
		self.resized_sizes = resized_sizes
		self.resized_data = resized_data
	
	def process_split(self, split_bucket):
		for bucket in split_bucket['children']:
			if bucket['name'].lower() == 'train':
				self.training_images = bucket['content']
			elif bucket['name'].lower() == 'test':
				self.testing_images = bucket['content']
	
	def create_random_split(self, verbose=True):
		"""
		Create a random train / test split
		"""
		
		self.training_images = set()
		self.testing_images = set()
		
		leaf_categories = self.get_leaf_categories()
		for category in leaf_categories:
			category_images = category.images
			train = [img for img in random.sample(category_images, len(category_images) / 2) if img not in self.testing_images]
			self.training_images.update(train)
			test = [img for img in category_images if img not in self.training_images]
			self.testing_images.update(test)
			
			# are there any images that didn't make it into either split? 
			left_overs = set(category_images).difference(self.training_images | self.testing_images)
			for img in left_overs:
				if img not in self.training_images:
					self.training_images.add(img)
				else:
					self.testing_images.add(img)
		
		# sanity checks
		assert len(self.training_images.intersection(self.testing_images)) == 0, "Mixing training and testing data!"
		# There could be images not in a leaf category...
		#assert len(self.training_images | self.testing_images) == len(self.image_data), "Not using all of the images? %d vs %d" % (len(self.training_images | self.testing_images), len(self.image_data))
		
		self.training_images = list(self.training_images)
		self.testing_images = list(self.testing_images)
		
		if verbose:
			print "Number of training images: %d" % (len(self.training_images),)
			print "Number of testing images: %d" % (len(self.testing_images),)
		
	def get_category_by_name(self, name):
		
		if name in self.category_cache:
			return self.category_cache[name]
		else:
			cat = self.category_root.get_descendant_by_name(name)
			if cat != None:
				self.category_cache[name] = cat
			return cat
	
	def get_category_by_int_id(self, int_id):
		
		if int_id in self.category_cache:
			return self.category_cache[int_id]
		else:
			cat = self.category_root.get_descendant_by_int_id(int_id)
			if cat != None:
				self.category_cache[int_id] = cat
			return cat
	
	def get_leaf_categories(self):
		
		return self.category_root.get_leaf_categories()
	
	# FIX ME: Needs to be done in parallel
	def download_images(self, verbose=True):
		"""
		Use this to download all images in the dataset. Otherwise they will download lazily 
		as they are needed.
		"""
		download_count = 0
		successful_image_ids = []
		failed_image_ids = []
		total_images = len(self.image_data)
		count = 0
		if verbose:
			print "Downloading Potentially %d images." % (total_images,)
		
		for image_id, image_url_suffix in self.image_data.iteritems():
			try:
				local_image_path = os.path.join(self.image_cache, image_url_suffix)
				if not os.path.isfile(local_image_path):
					image_url = urllib.basejoin(self.image_url_prefix, image_url_suffix)
					urllib.urlretrieve(image_url, local_image_path)
					download_count += 1
				successful_image_ids.append(image_id)
				count += 1
				if verbose:
					 print_progress(count, total_images)
			except:
				failed_image_ids.append(image_id)
				continue
		if verbose:
			print "Downloaded %d images." % (download_count,)
			print "Success for %d / %d images." % (len(successful_image_ids), total_images)
			print "Failed for %d / %d images." % (len(failed_image_ids), total_images)
		
		return successful_image_ids, failed_image_ids
	
	def convert_to_uuid(self, image_id):
		return str(uuid.UUID(image_id))
	
	def get_image_name(self, image_id):
		image_id = self.convert_to_uuid(image_id)
		return self.image_data[image_id]
	
	def get_image_url(self, image_id):
		image_id = self.convert_to_uuid(image_id)
		return os.path.join(self.image_url_prefix, self.image_data[image_id])
	
	def get_image_local_path(self, image_id):
		image_id = self.convert_to_uuid(image_id)
		return os.path.join(self.image_cache, self.image_data[image_id])
			
	def get_image(self, image_id):
		image_id = self.convert_to_uuid(image_id)
		image_url_suffix = self.image_data[image_id]
		local_image_path = os.path.join(self.image_cache, image_url_suffix)
		if not os.path.isfile(local_image_path):
			image_url = urllib.basejoin(self.image_url_prefix, image_url_suffix)
			urllib.urlretrieve(image_url, local_image_path)
		
		image = imread(local_image_path)
		
		return image
	
	def get_all_image_identifiers(self):
		return self.image_data.values()
	
	def get_image_url_for_size(self, image_id, size_id):
		image_id = self.convert_to_uuid(image_id)
		if image_id in self.resized_image_data and size_id in self.resized_image_data[image_id]:
			return os.path.join(self.image_url_prefix, self.resized_image_data[image_id][size_id])
		else:
			return self.get_image_url(image_id)
	
	def prepare_image_splits(self, recreate=False):
		"""
		This will create a train / test split, and then save the split so that it can be used later on
		"""
		if os.path.exists(self.image_split_path) and not recreate:
			raise RuntimeError('image split file already exists')
		
		if self.training_images == None or self.testing_images == None:
			self.create_random_split()
		
		split_data = {'train' : self.training_images, 'test' : self.testing_images}
		
		with open(self.image_split_path, 'w') as f:
			json.dump(split_data, f)
	
	# Create a json bucket hierarchy that contains the nodes (and their parents / children) with the specified name
	def create_subset_hierarchy(self, names):
		
		names = set(names)
		
		bucket_hierarchy = copy.deepcopy(self.raw_category_hierarchy)
		
		# Mark all descendants of this bucket
		def keep_buckets(bucket):
			if 'children' in bucket and len(bucket['children']):
				for child in bucket['children']:
					child['delete'] = False
					keep_buckets(child)
		
		def deletion_mark(bucket):
			
			keep_around = False
			
			if bucket['name'] in names:
				keep_around = True
				keep_buckets(bucket)
			else:
				if 'children' in bucket and len(bucket['children']):
					for child in bucket['children']:
						keep_around |= deletion_mark(child)
			
			#if bucket['name'] not in names and not keep_around:
			#	print "Did not Find %s" % (bucket['name'],)
			
			bucket['delete'] =  not keep_around		
			return keep_around
		
		deletion_mark(bucket_hierarchy)
		
		if not bucket_hierarchy['delete']:
			del bucket_hierarchy['delete']
			bucket_queue = [bucket_hierarchy]
			for bucket in bucket_queue:
			
				new_children_list = [copy.deepcopy(child) for child in bucket['children'] if not child['delete']]
				for child in new_children_list:
					del child['delete']
				bucket_queue += new_children_list
				bucket['children'] = new_children_list
					
		else:
			bucket_hierarchy = {'name' : 'hierarchy', 'children' : []}
		
		
		return {'buckets' : bucket_hierarchy}
		

class Category(object):
	
	def __init__(self, bucket, dataset, parent=None):
		
		self.dataset = dataset
		self.parent = parent
		
		self.name = bucket['name']
		self.images = bucket['content']
		self.int_id = bucket['id']
		
		if 'details' in bucket and 'description' in bucket['details']:
			self._details = bucket['details']['description']
		
		self.children = []
		for child in bucket['children']:
			child_category = Category(child, dataset, self)
			self.children.append(child_category)
		self.is_leaf = len(self.children) == 0
	
	@property
	def details(self):
		return self._details	
		
	@property
	def images(self):
		return self._images
	@images.setter
	def images(self, images):
		self._images = images
	
	def get_descendant_by_name(self, name):
		"""
		Return the category that corresponds to the name
		"""
		if name == self.name:
			return self
		else:
			for child in self.children:
				cat = child.get_descendant_by_name(name)
				if cat != None:
					return cat
		return None
	
	def get_descendant_by_int_id(self, int_id):
		"""
		Return the category that corresponds to the name
		"""
		if int_id == self.int_id:
			return self
		else:
			for child in self.children:
				cat = child.get_descendant_by_int_id(int_id)
				if cat != None:
					return cat
		return None
	
	def get_leaf_categories(self):
		
		if self.is_leaf:
			return [self]
		else:
			leaves = []
			for child in self.children:
				leaves += child.get_leaf_categories()
			return leaves
		
	# Produces a simple json representation of the bucket
	def json_copy(self):
		
		children_copy = []
		for child in self.children:
			children_copy.append(child.copy())
		
		return {
				'name' : self.name, 
				'children' : children_copy,
				'content' : copy.deepcopy(self.images)
			   }
			
		
						
			
		
