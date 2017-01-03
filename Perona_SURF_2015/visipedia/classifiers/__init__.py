import numpy as np
from scipy.misc import imread

from sklearn import metrics
from sklearn.base import BaseEstimator, ClassifierMixin
import struct
import PIL
from PIL import Image
from visipedia.extractors.regions.utils import *
import requests
from base64 import decodestring
import cStringIO
from skimage import transform
import os

def get_image(url):
	"""
	We could do several things here, like download the image from the web, etc. For now
	just assume that it is a local file path. 
	"""
	return imread(url)


def load_image(image_data):
        if 'image_data' in image_data:
                bstr = image_data['image_data'].split(',')[-1]  # because the string might have a header
                return Image.open(cStringIO.StringIO(decodestring(bstr)))
        
        image_url = image_data['url']
		
        if image_url.startswith('file://'):
                try:
                        return Image.open(image_url[7:])
                except:
                        return None
        else:
                image_req = requests.get(image_url, verify=False, timeout=20)
                if image_req.status_code == 200:
                        try:
                                return Image.open(io.BytesIO(image_req.content))
                        except:
                                return None
                
        logging.info("Failed to download image from: %s" % (image_url, ))
        return None

def compute_feature_for_image(image_pil, model_data, model_annotation, extractor_data, vis_file_base_name=None):
	"""
	Convenience function to compute a feature vector for the given model from the given image. 
	image_pil -- a PIL image
	model_data -- the model definition
	model_annotation -- the model annotation data
	extractor_data -- an array of extraction components, each producing a feature vector
		that will be concatenated together. Each inner array element has the following 
		components:
			region_extractor -- an object that has an `extract` method and returns a ndarray
			region_extract params -- extra parameters to pass to the region extractor `extract` method
			feature_extractor -- an object that has an `extract` method and returns a 1xN feature vector
			feature_extractor params -- extra parameters to pass to the feature extractor `extract` method
	
	Returns a feature vector
	"""
	
        image = np.asarray(image_pil)
	total_feature = None
        image_padded = None
        model_annotation_padded = None
        
	for region_extractor, region_kwargs, feature_extractor, feature_kwargs in extractor_data:
                if hasattr(region_extractor, 'pad_image') and region_extractor.pad_image:
                        if image_padded is None:
                                image_padded_pil = pad_image(image_pil, image_pil.size[0]/2, image_pil.size[1]/2)
                                image_padded = np.asarray(image_padded_pil)
                                model_annotation_padded = pad_annotation(model_annotation, image_pil.size[0]/2, image_pil.size[1]/2, image_size=image_pil.size)
                                
                        img = image_padded_pil if hasattr(region_extractor, 'pil_image') and region_extractor.pil_image else image_padded
                        region = region_extractor.extract(img, model_data, model_annotation_padded, vis_file_base_name=vis_file_base_name, **region_kwargs)
                        feature = feature_extractor.extract(region, model_data, model_annotation_padded, **feature_kwargs)
                
                else:
                        img = image_pil if hasattr(region_extractor, 'pil_image') and region_extractor.pil_image else image
                        region = region_extractor.extract(img, model_data, model_annotation, vis_file_base_name=vis_file_base_name, **region_kwargs)
                        feature = feature_extractor.extract(region, model_data, model_annotation, **feature_kwargs)
		
		if total_feature == None:
			total_feature = np.copy(feature)
		else:
			total_feature = np.hstack((total_feature, feature)) 
	
	return total_feature
	
def compute_features(image_data, model_data, extractor_data, category_data):
	"""
	Convenience function to produce a feature matrix for the given model from the given images.
	Each row in the returned feature matrix represents a feature from an image.  
	The number of rows in the feature matrix is equal to the length of the category_data array. 
	See `compute_feature_for_image` for details on the parameters. 
	"""
	all_features = []
	
	for (image_id, annotation_index, category_id) in category_data:
		
		print image_id
		image_details = image_data[image_id]
		image = get_image(image_details['url'])
		model_annotation = image_details['annotations'][annotation_index]	
		
		total_feature = compute_feature_for_image(image, model_data, model_annotation, extractor_data)
	 	all_features.append(total_feature)
	 	
	return np.array(all_features)


def extract_image_regions(image_data, model_data, model_annotations, extractor_data, data_dir, image_size=None):
	"""
        Save all warped regions to disk for an entire dataset.  A subdirectory will be created for each region type inside the
        directory data_dir, and a warped image <image_id>.jpg will be saved to that subdirectory
	image_data -- Dictionary of images defining a dataset
	model_data -- the model definition
	model_annotation -- the model annotation data
	extractor_data -- an array of extraction components, each producing a feature vector
		that will be concatenated together. Each inner array element has the following 
		components:
			region_extractor -- an object that has an `extract` method and returns a ndarray
			region_extract params -- extra parameters to pass to the region extractor `extract` method
			feature_extractor -- an object that has an `extract` method and returns a 1xN feature vector
			feature_extractor params -- extra parameters to pass to the feature extractor `extract` method
	"""
        model_annotations_by_id = {}
        for a in model_annotations:
                model_annotations_by_id[a["image_id"]] = a["components"]
        for region_extractor, region_kwargs, feature_extractor, feature_kwargs in extractor_data:
                if not os.path.exists(data_dir + "/" + region_extractor.name):
                        os.makedirs(data_dir + "/" + region_extractor.name)
        for image_id in image_data:
                image_pil = load_image(image_data[image_id])
                image = np.asarray(image_pil)
                image_padded = None
                model_annotation_padded = None
                model_annotation = model_annotations_by_id[image_id]
        
                for region_extractor, region_kwargs, feature_extractor, feature_kwargs in extractor_data:
                        if hasattr(region_extractor, 'pad_image') and region_extractor.pad_image:
                                if image_padded is None:
                                        image_padded_pil = pad_image(image_pil, image_pil.size[0]/2, image_pil.size[1]/2)
                                        image_padded = np.asarray(image_padded_pil)
                                        model_annotation_padded = pad_annotation(model_annotation, image_pil.size[0]/2, image_pil.size[1]/2, image_size=image_pil.size)
                                        
                                img = image_padded_pil if hasattr(region_extractor, 'pil_image') and region_extractor.pil_image else image_padded
                                region = region_extractor.extract(img, model_data, model_annotation_padded, vis_file_base_name=None, **region_kwargs)
                        
                        else:
                                img = image_pil if hasattr(region_extractor, 'pil_image') and region_extractor.pil_image else image
                                region = region_extractor.extract(img, model_data, model_annotation, vis_file_base_name=None, **region_kwargs)
                        
                        if image_size: 
                                #region = region.resize(image_size, PIL.Image.ANTIALIAS)
                                region = transform.resize(region, image_size)
                        
                        fname = data_dir + "/" + region_extractor.name + "/" + str(image_id) + ".jpg"
                        Image.fromarray(numpy.uint8(region*255)).save(fname, "JPEG")
        


def train_classifier(classifier, category_data, feature_data, subset_image_ids=None):
	"""
	Convenience method to train a classifier on the given data. 
	classifier : an object that has a fit() method
	category_data : an array of the form [image_id, annotation_id, category_id]
	feature_data : a NxM numpy ndarray of N features of length M. This can be a superset of the features actually used for training
	subset_image_ids : an array of image identifiers that represent the subset of data to use. If this None, then all features are used to train the classifier
	
	returns the classifier object
	"""
	
	category_labels = np.array([x[2] for x in category_data])
	
	if subset_image_ids != None:
		
		image_ids = [x[0] for x in category_data]
		
		# hash the subset ids for faster lookup
		hashed_subset = set(subset_image_ids)
		valid_indices = [i for i, x in enumerate(image_ids) if x in hashed_subset]	
		features = feature_data[valid_indices]
		category_labels = category_labels[valid_indices]
	
	else:
		features = feature_data
	
	classifier.fit(features, category_labels)
	
	return classifier

def test_classifier(classifier, category_data, feature_data, subset_image_ids=None):
	"""
	Convenience method to test a classifier on the given data. 
	classifier : an object that has a predict() method
	category_data : an array of the form [image_id, annotation_id, category_id]
	feature_data : a NxM numpy ndarray of N features of length M. This can be a superset of the features actually used for training
	subset_image_ids : an array of training image identifiers. If this None, then all features are used to train the classifier
	
	returns (subset_category_data, predicted labels)
	The subset_category_data is a subset of the category data array, and has the true labels of the features (along with the image ids, and annotation ids)
	"""
	
	if subset_image_ids != None:
		
		image_ids = [x[0] for x in category_data]
		
		# hash the subset ids for faster lookup
		hashed_subset = set(subset_image_ids)
		valid_indices = [i for i, x in enumerate(image_ids) if x in hashed_subset]	
		features = feature_data[valid_indices]
		subset_category_data = [category_data[x] for x in valid_indices]
	else:
		features = feature_data
		subset_category_data = category_data
	
	predicted_category_labels = classifier.predict(features)
	
	return (subset_category_data, predicted_category_labels)

def test_classifier_top_k(classifier, category_data, feature_data, subset_image_ids=None, max_k=10):
	
	"""
	Convenience method to test a classifier on the given data. 
	classifier : an object that has a predict_proba() or decision_function() method. This also has a classes_ attribute.
	category_data : an array of the form [image_id, annotation_id, category_id]
	feature_data : a NxM numpy ndarray of N features of length M. This can be a superset of the features actually used for training
	subset_image_ids : an array of training image identifiers. If this None, then all features are used to train the classifier
	max_k : for each k in range(1, max_k +1) an accuracy score will be returned. 
	
	returns (subset_category_data, predicted labels)
	The subset_category_data is a subset of the category data array, and has the true labels of the features (along with the image ids, and annotation ids)
	"""
	
	if subset_image_ids != None:
		
		image_ids = [x[0] for x in category_data]
		
		# hash the subset ids for faster lookup
		hashed_subset = set(subset_image_ids)
		valid_indices = [i for i, x in enumerate(image_ids) if x in hashed_subset]	
		features = feature_data[valid_indices]
		subset_category_data = [category_data[x] for x in valid_indices]
	else:
		features = feature_data
		subset_category_data = category_data
		
	try:
		y_probs = classifier.predict_proba(features)
	except:
		y_probs = classifier.decision_function(features)
		
	y_k_pred = {}
	for i in range(1, max_k+1):
		y_k_pred[i] = []
	
	category_labels = np.array([x[2] for x in subset_category_data])
		
	for correct_class, class_probs in zip(category_labels, y_probs):
		
		merged = zip(class_probs, classifier.classes_)
		merged.sort(key=lambda x: x[0])
		merged.reverse()
		class_orders = [x[1] for x in merged]
		
		for k in range(1, max_k+1):
			if correct_class in class_orders[:k]:
				y_k_pred[k].append(correct_class)
			
			else:
				y_k_pred[k].append(-1)
	
	accuracy_scores = [metrics.accuracy_score(category_labels, y_k_pred[k]) for k in range(1, max_k+1)]
	
	return accuracy_scores

def pad_image(img, pad_x, pad_y):
        ''' Pad an image by duplicating the pixels along the border '''
        [sz_x,sz_y] = img.size
        newImg = Image.new("RGB", (sz_x+2*pad_x,sz_y+2*pad_y))
        newImg.paste(img, (pad_x,pad_y,pad_x+sz_x,pad_y+sz_y))
        v_line1 = img.crop((0,0,1,sz_y))
        v_line2 = img.crop((sz_x-1,0,sz_x,sz_y))
  
        for i in range(0,pad_x):
                newImg.paste(v_line1, (i,pad_y,i+1,pad_y+sz_y))
                newImg.paste(v_line2, (pad_x+sz_x+i,pad_y,pad_x+sz_x+i+1,pad_y+sz_y))
  
        h_line1 = newImg.crop((0,pad_y,sz_x+2*pad_x,pad_y+1))
        h_line2 = newImg.crop((0,pad_y+sz_y-1,sz_x+2*pad_x,pad_y+sz_y))
  
        for i in range(0,pad_y):
                newImg.paste(h_line1, (0,i,sz_x+2*pad_x,i+1))
                newImg.paste(h_line2, (0,pad_y+sz_y+i,sz_x+2*pad_x,pad_y+sz_y+i+1))
  
        return newImg

def pad_annotation(annos, pad_x, pad_y, image_size=None):
        ''' Adjust annotation locations to be compatible with an image created using pad_image() '''
        annos_padded = annos[:]
        for a in annos_padded:
                (x,y,vis) = parse_geo_json(a['annotation'], image_size=image_size)
                if vis:
                        a['annotation'] = encode_geo_json(x+pad_x, y+pad_y, vis, image_size=(image_size[0]+2*pad_x, image_size[1]+2*pad_y))
        
        return annos_padded


class MulticlassSVMClassifier(BaseEstimator, ClassifierMixin):
        def __init__(self, eps=0.01, normalize=True, lambd=0.000002, multithread=False, dataset_too_big_for_memory=True, train_file=None, model_file=None, exe_name='structured_svm_multiclass.out', num_classes=None, num_features=None):
                self.eps = eps
                self.normalize = normalize
                self.lambd = lambd
                self.multithread = multithread
                self.dataset_too_big_for_memory = dataset_too_big_for_memory
                self.train_file = train_file
                self.model_file = model_file
                self.exe_name = exe_name
                self.num_classes = num_classes
                self.num_features = num_features
          
        def fit(self, X, Y):
                assert self.train_file, '"train_file" must be set, maybe you should use the default scikitlearn svm instead'
                assert self.model_file, '"model_file" must be set, maybe you should use the default scikitlearn svm instead'
                opts = " -L " + str(lambd) 
                opts2 = " -N -r 1" if self.normalize else " -r 1"
                if self.dataset_too_big_for_memory:
                        opts2 += " -D no_dataset"
                if self.multithread:
                        opts2 += " -T 1"
                sysTrain = self.exe_name + ' -d "' + self.train_file + '" -o "' + self.model_file + '" ' + opts + opts2 
                self.num_classes = Y.max()
                self.num_features = X.shape(0)
                self.write_feature_file(self.train_name, Y, X)
                os.system(sysTrain)
        
        def decision_function(self, X):
                return np.atleast_2d(X).dot(self.W).tolist()
        
        def read_weights(self):
                with open(self.model_file, 'rb') as fin:
                        data = fin.read(struct.calcsize('=II'))
                        if len(data) < struct.calcsize('=II'): return None
                        [isNonSparse, maxInd] = struct.unpack('=II', data)
                        data = fin.read(struct.calcsize('d'*(maxInd+1)))
                        if len(data) < struct.calcsize('d'*(maxInd+1)): return None
                        fv = struct.unpack('d'*(maxInd+1), data)
                        if not self.num_features:
                                self.num_features = len(fv)/self.num_classes
                        assert len(fv) == self.num_classes*self.num_features, 'Unexpected weight vector length ' + str(len(fv)) + '!='+str(self.num_classes)+'X'+str(self.num_features) + ' in ' + self.model_file
                        self.W = np.array(fv).reshape((self.num_classes, self.num_features)).T
        
        def write_feature_vector(self, cl, fv, fout, binary=False):
                inds = where(fv!=0)[0].tolist()
                if binary:
                        if not fout is None:
                                fout.write(struct.pack('=iIII', int(cl), 0, len(inds), len(fv)-1))
                                for i in inds:
                                        fout.write(struct.pack('Id', i, fv[i]))
                                return
                        else:
                                s = struct.pack('=iIII', int(cl), 0, len(inds), len(fv)-1)
                                for i in inds:
                                        s += struct.pack('Id', i, fv[i])
                else:
                        s = str(cl)
                        for i in inds:
                                s += " " + str(i)+":"+str(fv[i])
                        s += '\n'
                        if not fout is None:
                                fout.write(s)
                        else:
                                return s
        
        def write_feature_file(self, fname, cls, fvs):
                BI = "b" if fname.endswith(".bin") else ""
                B = True if fname.endswith(".bin") else False
                fout = open(fname,"w"+BI)
                for i in range(0,len(fvs)):
                        write_feature_vector(cls[i], fvs[i], fout, B)
                        fout.close()
