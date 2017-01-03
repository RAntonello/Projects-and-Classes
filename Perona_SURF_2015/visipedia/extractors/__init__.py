class BaseExtractor(object):
	"""
	This is the base extractor class. Region extractors and feature extractors will extend
	from this object. The important method is `extract`, which all children will inherit and 
	should override. The `extract` method is guaranteed to receive at least the following 
	parameters:
		image -- a numpy ndarray that is the image data to process 
		model_data -- the model definition data
		annotation_data -- the model annotation data
	
	Children of this class can pass extra arguments to the extract method using the 
	**kwargs parameter. 
	
	QUESTION: Should region extractors and feature extractors be separated? Do feature
	extractors need to know about the model_data and annotation_data? They return different 
	things....
	
	"""
	
	def __init__(self):
		self.notes = ''
		self.next_extractor = None
		
	@property
	def notes(self):
		return self._notes
	
	@notes.setter
	def notes(self, notes):
		self._notes = notes
	
	def extract(self, image, model_data, annotation_data, **kwargs):
		"""
		image -- a numpy ndarray that represents the image must be at least 2d
		model_data -- the model representation structure
		annotation_data -- the annotation data for the model 
		"""
		return image
