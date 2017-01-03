import numpy
import numpy as np
from PIL import Image
from skimage import transform

from visipedia.extractors import BaseExtractor
from utils import *

class BoundingBoxExtractor(BaseExtractor):
	
	def __init__(self, part_id=None, scale_factor=None, resize_shape=None, extra_notes=""):
		"""
		part_id : the part id of the bbox in the model data
		scale_factor : a factor to enlarge the bounding box by. The center of the bounding box will be maintained
		resize_shape : a (height, width) tuple to resize the bounding box to
		"""
		
		super(BoundingBoxExtractor, self).__init__()
		
		self.part_id = part_id
		self.scale_factor = scale_factor
		self.resize_shape = resize_shape
		self.notes = "\n".join(["Bounding Box Region Extractor", 
								"Part Id: %s" % (part_id,),
								"Scale Factor: %s" % (scale_factor,),
								"Resize Shape: %s" % (resize_shape,),
								extra_notes])
	
	# BUG: Currently doesn't handle the orientation factor
	def extract(self, image, model_data, annotation_data, **kwargs):	
		"""
		image -- a numpy ndarray that represents the image, must be at least 2d
		model_data -- the model representation structure
		annotation_data -- the annotation data for the model 
		"""
		
		x, y, width, height, orientation, visible, view_index = annotation_data[self.part_id]
		
		if not visible:
			return None
		
		image_height, image_width = image.shape[:2]
		
		# x and y are relative to the center of the bounding box
		x = x - (width / 2.0)
		y = y - (height / 2.0)
		
		bbox_x = int(max(0, x * image_width))
		bbox_y = int(max(0, y * image_height))
		bbox_width = int(min(image_width - bbox_x, width * image_width))
		bbox_height = int(min(image_height - bbox_y, height * image_height))
		
		return self.extract_bbox(image, bbox_x, bbox_y, bbox_width, bbox_height)
	
	def extract_bbox(self, image, bbox_x, bbox_y, bbox_width, bbox_height):
		"""
		image -- a numpy ndarray that represents the image must, be at least 2d
		bbox_x -- (int) the column index of the upper left corner of the bounding box, in image coordinates.
		bbox_y -- (int) the row index of the upper left corner of the bounding box, in image coordinates.
		bbox_width -- (int) the width of the bbox, in image coordinates
		bbox_height -- (int) the height of the bbox, in image coordinates
		"""
		
		if self.scale_factor != None:
			
			image_height, image_width = image.shape[:2]
			
			scale_factor = self.scale_factor
			
			half_width = bbox_width / 2
			half_height = bbox_height / 2
			
			bbox_center_x = bbox_x + half_width
			bbox_center_y = bbox_y + half_height
			
			# we want the object to stay in the middle, so the expansion has to be the same in both directions for each axis.
			width_expansion = min(bbox_center_x - max(int(bbox_center_x - scale_factor * half_width), 0), min(int(bbox_center_x + scale_factor * half_width), image_width) - bbox_center_x)
			height_expansion = min(bbox_center_y - max(int(bbox_center_y - scale_factor * half_height), 0), min(int(bbox_center_y + scale_factor * half_height), image_height) - bbox_center_y)
			
			bbox_x1 = bbox_center_x - width_expansion
			bbox_x2 = bbox_center_x + width_expansion
			bbox_y1 = bbox_center_y - height_expansion
			bbox_y2 = bbox_center_y + height_expansion
			
			crop = image[bbox_y1:bbox_y2, bbox_x1:bbox_x2]
			
		else:
			bbox_x1 = bbox_x
			bbox_x2 = bbox_x + bbox_width
			bbox_y1 = bbox_y
			bbox_y2 = bbox_y + bbox_height
		
		crop = image[bbox_y1:bbox_y2, bbox_x1:bbox_x2]
		
		if self.resize_shape != None:
			crop = transform.resize(crop, self.resize_shape)
			
		return crop
		
class WarpRegionExtractor(BaseExtractor):
	
	FLIP_LEFT_RIGHT = 1
	FLIP_TOP_BOTTOM = 2
	FLIP_180 = 3
	
	def __init__(self, part_ids=None, warp_points=None, warp_shape=None, shear=True, scale=True, check_flips=None, extra_notes=""):
		"""
		part ids -- an array of parts ids to use for the warping calculations
		warp_points -- a numpy ndarry representing the points to warp to, in image coordinates. These should be in the same order as the part ids
		warp_shape -- a (height, width) tuple representing the resulting warp shape
		shear -- allowing shearing
		scale -- allowing scaling
		check_flips -- an array of flip identifiers that specify which flips to check when searching for the optimal warping
		"""
		
		super(WarpRegionExtractor, self).__init__()
		
		self.part_ids = part_ids
		self.warp_points = warp_points
		self.warp_shape = warp_shape # This needs to be (width, height)
		self.shear = shear
		self.scale = scale
		self.check_flips = check_flips if check_flips else []
		self.notes = "\n".join(["Warp Region Extractor",
								"Part Ids: %s" % (part_ids, ), 
								"Warp Points: %s" % (warp_points,),
								"Warp Shape: %s" % (warp_shape,),
								"Shear: %s" % (shear,),
								"Scale: %s" % (scale,),
								"Check Flip: %s" % (check_flips,),
								extra_notes])
	
	# BUG: Currently doesn't handle non-visible parts
	def extract(self, image, model_data, annotation_data, **kwargs):
		"""
		image -- a numpy ndarray that represents the image, must be at least 2d
		model_data -- the model representation structure
		annotation_data -- the annotation data for the model 
		"""
		
		part_matrix = []
		
		for part_id in self.part_ids:
			x, y, width, height, orientation, visible, view_index = annotation_data[part_id]
			
			if not visible:
				return None
				
			part_matrix.append([y, x])
		
		part_matrix = np.array(part_matrix)
		
		warped_pil_image, A, loss = self.determine_warping_for_image(self.warp_points, part_matrix, Image.fromarray(image), self.warp_shape[::-1], check_flips=self.check_flips, shear=self.shear, scale=self.scale)
		
		return np.array(warped_pil_image)
		
	def determine_warping_for_image(self, to_points, from_points, source_image, warp_size, check_flips=None, shear=True, scale=True):
		"""
		to_points : the points that we are warping to. These are NOT in [0,1]
		from_points : the point that we are warping from. These ARE in [0,1]
		source_image : the image that will be warped, this is a PIL Image
		warp_size : the shape of the warped region. This needs to be (width, height), PIL format
		check_flips : an array of flip identifiers that specify which flips to check when searching for the optimal warping 
		shear : For affine transforms, can we shear?
		scale : For affine and rigid transformations, can we scale?
		
		Returns (warped_image, transformation_matrix, loss)
		"""
		
		source_image_width, source_image_height = source_image.size
		source_image_size = np.array([source_image_height, source_image_width]) # this is in numpy format
		image_to_transform = source_image
		
		if len(check_flips) == 0:
			
			p2 = from_points * source_image_size
			A = affine_matrix_from_points(to_points.T, p2.T, shear=shear, scale=scale)
			
			# compute the squared loss
			homogenous_p2 = np.hstack((p2, np.ones((p2.shape[0], 1))))
			A_inv = np.linalg.inv(A)
			A_mat = np.vstack((A_inv[0], A_inv[1]))
			warped_p2 = np.dot(A_mat, homogenous_p2.T).T
			loss = np.square(to_points-warped_p2).sum()
			
		# we want to flip the image to look for a better fit
		else:
			
			transform_data = []
			
			xs = np.atleast_2d(from_points[:,1]).T
			ys = np.atleast_2d(from_points[:,0]).T
			flipped_xs = np.atleast_2d(1 - from_points[:,1]).T
			flipped_ys = np.atleast_2d(1 - from_points[:,0]).T
			
			modified_points = [(from_points, None)]
			
			if self.FLIP_LEFT_RIGHT in check_flips:
				modified_points.append( (np.hstack((ys, flipped_xs)), Image.FLIP_LEFT_RIGHT))
			if self.FLIP_TOP_BOTTOM in check_flips:
				modified_points.append((np.hstack((flipped_ys, xs)), Image.FLIP_TOP_BOTTOM))
			if self.FLIP_180 in check_flips:			  
				modified_points.append((np.hstack((flipped_ys, flipped_xs)), Image.ROTATE_180))
			
			for points, mod in modified_points:
				
				p2 = points * source_image_size
				A = affine_matrix_from_points(to_points.T, p2.T, shear=shear, scale=scale)
			
				# compute the squared loss
				homogenous_p2 = np.hstack((p2, np.ones((p2.shape[0], 1))))
				try:
					A_inv = np.linalg.inv(A)
				except:
					print "Points:" 
					print p2
					print "A:"
					print A
					raise
				A_mat = np.vstack((A_inv[0], A_inv[1]))
				warped_p2 = np.dot(A_mat, homogenous_p2.T).T
				loss = np.square(to_points-warped_p2).sum()
				
				transform_data.append((np.array(A, copy=True), loss, mod))
				
			
			transform_data.sort(key=lambda x: x[1])
			A, loss, mod = transform_data[0]
			if mod != None:
				image_to_transform = source_image.transpose(mod)
			
		# warp the image	
		warped_image = image_to_transform.transform(warp_size, Image.AFFINE, (A[1,1],A[1,0],A[1,2],A[0,1],A[0,0],A[0,2]), Image.BICUBIC)
		
		
		return warped_image, A, loss



class WarpRegionExtractorSteve(BaseExtractor):	
        """ 
        This class is currently redundant with WarpRegionExtractor and is a modification of Grant's class WarpRegionExtractor to make sure it
        produces the same output as Steve's feature extraction code.  Eventually we should merge these two classes.  A known difference is
        the way it handles non-visible points and flipping
        """
        FLIP_NONE = 0
	FLIP_LEFT_RIGHT = 1
	FLIP_TOP_BOTTOM = 2
	FLIP_180 = 3
	
	def __init__(self, part_ids=None, warp_points=None, warp_shape=None, shear=True, scale=True, check_flips=None, extra_notes="", flip_part_ids=None):
                self.initialize(part_ids=part_ids, warp_points=warp_points, warp_shape=warp_shape, shear=shear, scale=scale, 
                                check_flips=check_flips, extra_notes=extra_notes, flip_part_ids=flip_part_ids)
        
	def initialize(self, part_ids=None, warp_points=None, warp_shape=None, shear=True, scale=True, check_flips=None, extra_notes="", flip_part_ids=None, name = None, component_id_2_ind = None):
		"""
		part ids -- an array of parts ids to use for the warping calculations
		warp_points -- a numpy ndarry representing the points to warp to, in image coordinates. These should be in the same order as the part ids
		warp_shape -- a (height, width) tuple representing the resulting warp shape
		shear -- allowing shearing
		scale -- allowing scaling
		check_flips -- an array of flip identifiers that specify which flips to check when searching for the optimal warping
                flip_part_ids -- a dictionary of key-value pairs where each key is a flip identifier  to check when searching for the optimal warping 
                     and each value is an array of the same format as part_ids. For example, this is used to encode the fact that when you flip an image, 
                     the left eye should be swapped with the right eye
		"""
		
		super(WarpRegionExtractorSteve, self).__init__()
		
                self.pad_image = True
                self.pil_image = True
		self.part_ids = part_ids
		self.warp_points = warp_points
		self.warp_shape = warp_shape # This needs to be (width, height)
		self.shear = shear
		self.scale = scale
                self.name = name
		self.check_flips = check_flips if check_flips else []
                self.flip_part_ids = { self.FLIP_NONE : part_ids }
                self.component_id_2_ind = component_id_2_ind
                if flip_part_ids:
                        for i in flip_part_ids:
                                self.flip_part_ids[i] =  flip_part_ids[i]
		self.notes = "\n".join(["Warp Region Extractor",
								"Part Ids: %s" % (part_ids, ), 
								"Warp Points: %s" % (warp_points,),
								"Warp Shape: %s" % (warp_shape,),
								"Shear: %s" % (shear,),
								"Scale: %s" % (scale,),
								"Check Flip: %s" % (check_flips,),
								extra_notes])
                
        def extract(self, image, model_data, annotation_data, vis_file_base_name=None, return_pil=False, **kwargs):
		"""
		image -- a PIL image
		model_data -- the model representation structure
		annotation_data -- the annotation data for the model 
		"""
		
                assert 'parts' in model_data, 'Invalid model ' + str(model_data)
                assert len(model_data['parts']) <= len(annotation_data), "Annotation data length " + str(len(annotation_data)) + " doesn't match model length " + str(len(model_data['parts']))
		part_matrix = [None for i in range(len(model_data['parts']))]
		for i in range(len(annotation_data)):
                        (x,y,vis) = parse_geo_json(annotation_data[i]['annotation'], image_size=image.size)
                        if 'component_id' in annotation_data[i] and annotation_data[i]['component_id'] in self.component_id_2_ind:
                                part_matrix[self.component_id_2_ind[annotation_data[i]['component_id']]] = [float(x), float(y), float(vis)]
		
		part_matrix = np.array(part_matrix)
		
		warped_pil_image, A, loss = self.determine_warping_for_image(self.warp_points, part_matrix, image, self.warp_shape, shear=self.shear, scale=self.scale, vis_file_base_name=vis_file_base_name)
		
                if return_pil: return warped_pil_image
		else: return np.array(warped_pil_image)
        
        def determine_warping_for_image(self, to_points, from_points, source_image, warp_size, shear=True, scale=True, normalized=False, vis_file_base_name=None):
		"""
		to_points : the points that we are warping to. These are NOT in [0,1]
		from_points : the points that we are warping from. These ARE in [0,1]
		source_image : the image that will be warped, this is a PIL Image
		warp_size : the shape of the warped region. This needs to be (width, height), PIL format
		check_flips : an array of flip identifiers that specify which flips to check when searching for the optimal warping 
		shear : For affine transforms, can we shear?
		scale : For affine and rigid transformations, can we scale?
		
		Returns (warped_image, transformation_matrix, loss)
		"""
		
		image_to_transform = source_image
                w = 1 if normalized else source_image.size[0]
                h = 1 if normalized else source_image.size[1]
		ws = 1 if normalized else warp_size[0]
                hs = 1 if normalized else warp_size[1]

                modified_points = []
                for flip_type in self.flip_part_ids:
			transform_data = []
                        part_ids = self.flip_part_ids[flip_type]
                        vis_points = np.where(from_points[part_ids,2] > 0)[0]
			
			if flip_type == self.FLIP_NONE:
                                modified_points.append( (np.hstack((np.atleast_2d(from_points[part_ids,0]).T, 
                                                                    np.atleast_2d(from_points[part_ids,1]).T)), 
                                                         None, vis_points))
			if flip_type == self.FLIP_LEFT_RIGHT:
				modified_points.append( (np.hstack((w-np.atleast_2d(from_points[part_ids,0]).T, 
                                                                    np.atleast_2d(from_points[part_ids,1]).T)), 
                                                         Image.FLIP_LEFT_RIGHT, vis_points))
			elif flip_type == self.FLIP_TOP_BOTTOM:
				modified_points.append( (np.hstack((np.atleast_2d(from_points[part_ids,0]).T, 
                                                                    h-np.atleast_2d(from_points[part_ids,1]).T)), 
                                                         Image.FLIP_TOP_BOTTOM, vis_points))
			elif flip_type == self.FLIP_180:
				modified_points.append( (np.hstack((w-np.atleast_2d(from_points[part_ids,0]).T, 
                                                                    h-np.atleast_2d(from_points[part_ids,1]).T)), 
                                                         Image.ROTATE_180, vis_points))
			
                for points, mod, v in modified_points:
                        (A,loss,warped_p2) = affine_matrix_from_points_steve(to_points[v,:], points[v,:], shear=shear, scale=scale)
                        
                        # loss incurred for non-visible points is high (proportional to a pixel error the size of the image)
                        non_vis_loss = (max(ws,hs)**2) * (len(self.part_ids)-len(v))  
                        
                        # hack to decide whether or not to flip the image when using a rigid transform and exactly 2 points (hence
                        # no alignment error).  Favor the flip that maintains the same relative x-location between the two points
                        if scale and (not shear) and len(v)==2 and ((to_points[v[1],0]-to_points[v[0],0])!=(points[v[1],0]-points[v[0],0])):
                                non_vis_loss += 0.0001
                                
                        #print "from " + str(points[v,:]) + " to " + str(to_points[v,:]) + " " + str(loss+non_vis_loss) + " " + str(loss)
                        transform_data.append((np.array(A, copy=True), loss+non_vis_loss, mod))
                
                transform_data.sort(key=lambda x: x[1])
                A, loss, mod = transform_data[0]
                if mod != None:
                        image_to_transform = source_image.transpose(mod)
                
		# warp the image
                #print str(warp_size) + " * " + str(A) + " ** " + str(image_to_transform.size) + " " + str(mod)
		warped_image = image_to_transform.transform(warp_size, Image.AFFINE, (A[0,0],A[0,1],A[0,2],A[1,0],A[1,1],A[1,2]), Image.BILINEAR)
                if vis_file_base_name:
                        #image_to_transform.save(vis_file_base_name + "_padded_"+str(mod)+".jpg", "JPEG")
                        warped_image.save(vis_file_base_name + "_" + self.name + ".jpg", "JPEG")
		return warped_image, A, loss
        
        
        def parse_parameters(self, r, model):
		"""
                r : an object (usually from json parsing a config file or parameters over the network) encoding the parameters of this region extractor
                model: an object encoding the parameters of the part model, it should store the list of parts
                
		Returns a string if an error occurs, else returns None
		"""
                
                # Compute maps going from part name to part id, which may be different for flipped versions of the parts
                maps = { 'parts' : 'none', 'parts_flip_left_right' : 'left_right', 'parts_flip_top_bottom' : 'top_bottom', 'parts_flip_180' : 'flip_180' }
                part_name_2_id = {}
                for m in maps:
                        if m in model:
                                part_name_2_id[maps[m]] = {}
                                part_names = model[m]
                                for i in range(len(part_names)):
                                        part_name_2_id[maps[m]][part_names[i]] = i	
                
                # warped regions by aligning parts
                if not "name" in r: return 'Error: "name" missing' 
                if not "referencePoints" in r: return 'Error: "referencePoints" missing' 
                if not "referenceBBox" in r: return 'Error: "referenceBBox" missing'
                                       
                # Load the part locations of the canonical template, and the location of the bounding box around those points for feature extraction
                bbox = (float(r["referenceBBox"][0]), float(r["referenceBBox"][1]), float(r["referenceBBox"][2]), float(r["referenceBBox"][3]))
                part_ids = []
                warp_points = []
                for p in r["referencePoints"]:
                        if not p in part_name_2_id["none"]: return 'Error: "referencePoints" has unknown part "' + str(p) + '"'
                        part_ids.append(part_name_2_id["none"][p])
                        pt = r["referencePoints"][p]
                        warp_points.append( (float(pt[0])-bbox[0], float(pt[1])-bbox[1]) )
                                               
                # Compute mappings from part names to part ids
                flip_part_ids = None
                if "check_flips" in r:
                        flip_part_ids = {}
                        flip_ids = {'left_right':WarpRegionExtractorSteve.FLIP_LEFT_RIGHT, 
                                    'top_bottom':WarpRegionExtractorSteve.FLIP_TOP_BOTTOM, 
                                    'flip_180':WarpRegionExtractorSteve.FLIP_180 }
                        for check_flip in r["check_flips"]:
                                part_ids_flip = []
                                if not check_flip in flip_ids: return 'Error: "check_flips" has unknown flip type "' + str(check_flip) + '"'
                                if not check_flip in part_name_2_id: return 'Error: "' + check_flip + '" missing'
                                
                                for p in r["referencePoints"]:
                                        part_ids_flip.append(part_name_2_id[check_flip][p])
                                        
                                        flip_part_ids[flip_ids[check_flip]] = part_ids_flip
                                 
                self.initialize(part_ids=part_ids, warp_points=np.array(warp_points), 
                                warp_shape=(int(bbox[2]),int(bbox[3])), shear=(r["transform"]=="affine"), 
                                scale=(r["transform"]!="translation"), flip_part_ids=flip_part_ids, name=r["name"],
                                component_id_2_ind=part_name_2_id["none"]
                        )
                return None
        
