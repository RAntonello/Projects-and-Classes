import json
import time
import sys
sys.path.append("/home/rantonello/Code/Moths")
sys.path.append("/home/rantonello/Code/Moths/Moth Stuff")
import matplotlib
matplotlib.use('Agg')
import visipedia
import numpy as np
from sklearn.svm import LinearSVC
from sklearn.preprocessing import Normalizer
from sklearn.externals import joblib
from visipedia import classifiers
from visipedia.classifiers import summary
from visipedia.extractors import BaseExtractor
from visipedia.extractors.regions import BoundingBoxExtractor, WarpRegionExtractor
from visipedia.extractors.features.cnn_features import CaffeFeatures
from visipedia import vibe

dataset = vibe.Dataset('/home/rantonello/Code/Moths/image_cache3','/home/rantonello/Code/Moths/data_cache3')

dataset.bootup('/home/rantonello/Code/Moths/Big_New_Sorting2.json')

#dataset.prepare_image_splits()

category_data = []
for category in dataset.get_leaf_categories():
	for image_id in category.images:
		category_data.append([image_id, 0, category.int_id])

image_data = {}
for image_id in dataset.image_data:
	image_data[image_id] = {'url' : dataset.get_image_local_path(image_id),
							'annotations' : [[None]]
							}

model_data = {'parts' : [], 'views' : []}


if False:

	caffe_feature_extractor = CaffeFeatures('/home/rantonello/Code/caffe-master/models/bvlc_alexnet/bvlc_alexnet.caffemodel',
									  		'/home/rantonello/Code/caffe-master/models/bvlc_alexnet/deploy.prototxt', 
									  		num_output = 1000
									 	   )

	extractor_data = [[BaseExtractor(), {}, caffe_feature_extractor, {'layers' : ['fc7']}],]

	start_time = time.time()
	features = classifiers.compute_features(image_data, model_data, extractor_data, category_data)
	end_time = time.time()
	print "Compute Features Time: %s minutes" % ((end_time - start_time) / 60.0, )
	joblib.dump(features, '/home/rantonello/Code/Moths/data_cache3/fc7features_alex.jbl')
else:
	features = np.array(joblib.load('/home/rantonello/Code/Moths/data_cache3/fc7features_alex.jbl'))
	

clf = LinearSVC()
#normalizer = Normalizer(copy=False)
#normalizer.transform(features)
dataset.create_random_split()
training_image_ids = dataset.training_images
testing_image_ids = dataset.testing_images

start_time = time.time()
clf = classifiers.train_classifier(clf, category_data, features, training_image_ids)
end_time = time.time()
print "Classifier Train Time: %s minutes" % ((end_time - start_time) / 60.0, )

start_time = time.time()
gt_data, pred_labels = classifiers.test_classifier(clf, category_data, features, testing_image_ids)
accuracy_scores = classifiers.test_classifier_top_k(clf, category_data, features, testing_image_ids, 5)
end_time = time.time()
print "Classifier Test Time: %s minutes" % ((end_time - start_time) / 60.0, )
print accuracy_scores
summary.summarize(image_data, gt_data, pred_labels, 'summary', dataset, top_k_data=(range(1,6), accuracy_scores))
