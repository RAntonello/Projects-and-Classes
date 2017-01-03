import caffe
import sys
import numpy as np
from sklearn.externals import joblib
import json
from matplotlib import pyplot as plt

sys.path.append('/home/rantonello/Code')
from vibe import *

dataset = Dataset('/home/rantonello/Code/Moths/image_cache2','/home/rantonello/Code/Moths/data_cache2')

# First Time Only
if True:
    dataset.bootup('/home/rantonello/Code/Moths/Moth_Hierarchy_Sorting.json')
    dataset.download_images()
    dataset.create_random_split()
else:
    dataset.bootup()
    dataset.create_random_split()
    
MODEL_FILE = '/home/rantonello/Code/caffe-master/models/bvlc_alexnet/deploy.prototxt'
PRETRAINED = '/home/rantonello/Code/caffe-master/models/bvlc_alexnet/bvlc_alexnet.caffemodel'

caffe_root= '/home/rantonello/Code/caffe-master/'
caffe.set_mode_cpu()
net = caffe.Classifier(MODEL_FILE, PRETRAINED,
                        mean=np.load(caffe_root + 'python/caffe/imagenet/ilsvrc_2012_mean.npy').mean(1).mean(1),
                        channel_swap=(2,1,0),
                        raw_scale=255,
                        image_dims=(256, 256))

# WARNING: Needs to change based on the feature dimension
# e.g. net.blobs['pool5'].data[0].shape ==> (rows, cols)
print net.blobs['fc7'].data[0].shape
feature_matrix = np.zeros((len(dataset.image_data), 4096))
id_index_array = []

# Extract features from all the images, making sure to remember which vibe image id corresponds to which feature

# The strings to try are: conv5, pool5, fc6, fc7

for vibe_id in dataset.image_data:
    image = dataset.get_image(vibe_id)
    if image.size == 1:
        print "Bad image: %s" % (vibe_id,)
    if image.shape[0] == 0 or image.shape[1] == 0:
        print "Bad image: %s" % (vibe_id,)

for i, vibe_id in enumerate(dataset.image_data):
    try:    
        image = dataset.get_image(vibe_id)
        prediction = net.predict([image], oversample=False)
        feat = net.blobs['fc7'].data[0]
        id_index_array.append(vibe_id)
        feature_matrix[i] = feat # make sure that this actually copies the data into the matrix
        if i % 100 == 0:
            print i
    except:
        print
        print "Failed on vibe id: %s" % (vibe_id, )
        print
        raise

# (I have seen pointer issues with Caffe reusing the array for the next computation)


# Make sure to save the features and the image ids, so that we only have to extract the features once
joblib.dump(feature_matrix, '/home/rantonello/Code/Moths/data_cache/fc7features_alex.jbl')

with open('/home/rantonello/Code/Moths/data_cache/fc7imageids_alex.json', 'w') as f:
    json.dump(id_index_array, f)

# NOTE: the above code should probably be placed in its own "feature extraction routine"
# CHANGE: Here we could load in the features (if we are running the code a second time, etc.)

# We need to create our class labels, as well as the corresponding train test splits

'''
vibe_to_cat = {}

for cat in dataset.get_leaf_categories():
    for vibe_id in cat.images:
        vibe_to_cat[vibe_id] = cat.int_id

Y = np.array([vibe_to_cat[vibe_id] for vibe_id in id_index_array])

training_indices = []
test_indices = []
for i, vibeid in enumerate(id_index_array):
    if vibeid in dataset.training_images:
        training_indices.append(i)
    else:
        test_indices.append(i)

test_features = feature_matrix[test_indices]
training_features = feature_matrix[training_indices]

test_Y = Y[test_indices]
train_Y = Y[training_indices]

# Train and test a model. For now we will just use a simple linear svm. The default parameters should be fine
from sklearn import svm
from sklearn.metrics import accuracy_score, classification_report
clf = svm.LinearSVC(C=1)
clf.fit(training_features, train_Y)
pred_Y = clf.predict(test_features)

print classification_report(test_Y, pred_Y)

# Ok so at this point you have a classifier that you are happy with
# Lets use it to classify the unlabeled images
predictions_per_class = {}
for cat in dataset.get_leaf_categories():
    predictions_per_class[cat.int_id] = []
for vibe_id in dataset.image_data:
    if vibe_id not in dataset.training_images and vibe_id not in dataset.testing_images:
        # this is an unlabeled image, so lets classify it
        feature_index = id_index_array.index(vibe_id)
        feature = feature_matrix[feature_index]
        
        pred_label = clf.predict(feature)
        
        # we need to save off the predicted label for this image,
        predictions_per_class[pred_label].append(vibe_id)

        # For example, if you want to visualize the results...
        if False:
            image = dataset.get_image(vibe_id)
            plt.imshow(image)
            plt.title("Predicted Class= %s" % (dataset.get_category_by_int_id(pred_label).name))
            
with open('/home/rantonello/Code/Moths/data_cache/class_predictions.json', 'w') as f:
    json.dump(predictions_per_class, f)

# As a final step, you should take the final predictions and create a bucket structure that 
#you can upload to Vibe. Then we can visually see how well it did, and pass the results
# off to the Moth People
'''
