import sys, os

from jinja2 import Environment, FileSystemLoader
from matplotlib import pyplot as plt
from matplotlib.ticker import FuncFormatter
import numpy as np
from sklearn.metrics import accuracy_score, confusion_matrix

def summarize(image_data, category_data, predicted_identifiers, output_dir_path, dataset=None, default_image_size=4, top_k_data=None): 		
	"""
	image_data : a dictionary that maps the vibe uuid to the image details
	category_data : an array of the form [image_id, annotation_id, category_id], this is ground truth data
	predicted_identifiers : an array of the predicted category identifiers for each entry in the category data array
	output_dir_path : the path for the output files
	dataset : a vibe dataset parameter; allows for more data to be printed
	default_image_size : the default image size to use for the html files
	top_k_data : a tuple of the format ([kmin, ..., kmax], [accuracy_kmin, ..., accuracy_kmax])
	"""
	
	# create the output directory if it does not exits
	if not os.path.exists(output_dir_path):
		os.makedirs(output_dir_path)
	
	ground_truth_identifiers = [x[2] for x in category_data]
	
	category_identifiers = list(set(ground_truth_identifiers))
	category_identifiers.sort()
	if dataset:
		category_labels = [dataset.get_category_by_int_id(x).name for x in category_identifiers]
	else:
		category_labels = category_identifiers
	
	# Get the general accuracy of the classifier
	accuracy = accuracy_score(ground_truth_identifiers, predicted_identifiers)
	print accuracy
	# Create a python confusion matrix
	# make sure to order it by the category identifiers!
	cm = confusion_matrix(ground_truth_identifiers, predicted_identifiers, category_identifiers)
	
	################### Pyplot confusion matrix
	fig_edge_length = max(10, np.ceil(len(category_identifiers) / 5) + 2)
	fig = plt.figure(figsize=(fig_edge_length, fig_edge_length), dpi=80,)
	ax = fig.add_subplot(111)
	# we want to normalize each row
	row_sums = cm.sum(axis=1).astype(float)
	cm_to_render = cm / row_sums[:, np.newaxis]
	cax = ax.matshow(cm_to_render)
	def use_percent(x, pos):
		return '%d%%' % (int(x * 100),)
	fig.colorbar(cax, format=FuncFormatter(use_percent))
	plt.setp( ax.xaxis.get_majorticklabels(), rotation=90 )
	ax.set_xticks(range(len(category_labels)))
	ax.set_xticklabels(category_labels)
	ax.set_yticks(range(len(category_labels)))
	ax.set_yticklabels(category_labels)
	ax.set_xlabel('Predicted')
	ax.set_ylabel('True')
	fig.suptitle('Accuracy: %0.3f' % (accuracy,), y=-0.05)
	plt.savefig(os.path.join(output_dir_path, 'confusion_matrix.png'), bbox_inches='tight') 
	
	################## Details for each Category: True Positive, False Positive, False Negative Stuff
	# we want to produce some data structures for the True Positive, False Positive, and False Negative info
	details_dir_name = 'details'
	details_path = os.path.join(output_dir_path, details_dir_name)
	if not os.path.exists(details_path):
		os.makedirs(details_path)
	
	details_dir_html_links = {}
	
	category_results_data = dict([(cat_id, {'True Positive' : [], 'False Positive' : [], 'False Negative' : [], 'Total' : 0}) for cat_id in category_identifiers])
	
	for ((image_id, annotation_id, cat_id), pred_cat_id) in zip(category_data, predicted_identifiers):
		
		category_results_data[cat_id]['Total'] += 1
		
		if cat_id == pred_cat_id:
			category_results_data[cat_id]['True Positive'].append(image_id)
		
		else:
			category_results_data[cat_id]['False Negative'].append((image_id, pred_cat_id))
			category_results_data[pred_cat_id]['False Positive'].append((image_id, cat_id))
	
	jinja_env = Environment(loader = FileSystemLoader(os.path.join(os.path.split(os.path.realpath(__file__))[0], 'summary_templates/')))
	details_template = jinja_env.get_template('details.html')
	for cat_id, cat_label in zip(category_identifiers, category_labels):
		if dataset != None:
			true_positives = [dataset.get_image_url_for_size(image_id, default_image_size) for image_id in category_results_data[cat_id]['True Positive']]
			false_positives = [(dataset.get_image_url_for_size(image_id, default_image_size), category_labels[category_identifiers.index(actual_cat_id)]) for image_id, actual_cat_id in category_results_data[cat_id]['False Positive']]
			false_negatives = [(dataset.get_image_url_for_size(image_id, default_image_size), category_labels[category_identifiers.index(pred_cat_id)]) for image_id, pred_cat_id in category_results_data[cat_id]['False Negative']]
		else:
			true_positives = [image_data[image_id]['url'] for image_id in category_results_data[cat_id]['True Positive']]
			false_positives = [(image_data[image_id]['url'], category_labels[category_identifiers.index(actual_cat_id)]) for image_id, actual_cat_id in category_results_data[cat_id]['False Positive']]
			false_negatives = [(image_data[image_id]['url'], category_labels[category_identifiers.index(pred_cat_id)]) for image_id, pred_cat_id in category_results_data[cat_id]['False Negative']]
		
		template_data={
			'category_name' : cat_label, 
			'total_images' : category_results_data[cat_id]['Total'],
			'true_positives' : true_positives,
			'false_positives' : false_positives,
			'false_negatives' : false_negatives
		}
		
		t = details_template.render(**template_data)
		
		page_name = "%s.html" % (cat_id)
		with open(os.path.join(details_path, page_name), 'w') as f:
			print >> f, t
		
		details_dir_html_links[cat_id] = os.path.join(details_dir_name, page_name)
	
	#################### 1 on 1 Category Comparisons
	comparison_dir_name = 'comparisons'
	comparison_path = os.path.join(output_dir_path, comparison_dir_name)
	if not os.path.exists(comparison_path):
		os.makedirs(comparison_path)
	
	comparison_template = jinja_env.get_template('comparisons.html')
	
	comparison_html_links = {}
	
	rows, cols = np.nonzero(np.tril(cm + cm.T, -1))
	for cat_index_1, cat_index_2 in zip(rows, cols):
		
		cat_id_1 = category_identifiers[cat_index_1]
		cat_id_2 = category_identifiers[cat_index_2]
		
		cat_1_fn_that_went_to_cat_2 = []
		cat_2_fn_that_went_to_cat_1 = []
		
		for ((image_id, annotation_id, cat_id), pred_cat_id) in zip(category_data, predicted_identifiers):
			
			if cat_id_1 == cat_id and cat_id_2 == pred_cat_id:
				cat_1_fn_that_went_to_cat_2.append((image_id, annotation_id))
			
			if cat_id_2 == cat_id and cat_id_1 == pred_cat_id:
				cat_2_fn_that_went_to_cat_1.append((image_id, annotation_id))
		
		if dataset != None:
			category1_true_positives = [dataset.get_image_url_for_size(image_id, default_image_size) for image_id in category_results_data[cat_id_1]['True Positive']]
			category1_false_negatives = [dataset.get_image_url_for_size(x[0], default_image_size) for x in cat_1_fn_that_went_to_cat_2]

			category2_true_positives = [dataset.get_image_url_for_size(image_id, default_image_size) for image_id in category_results_data[cat_id_2]['True Positive']]
			category2_false_negatives = [dataset.get_image_url_for_size(x[0], default_image_size) for x in cat_2_fn_that_went_to_cat_1]
			
		else:
			category1_true_positives = 	[image_data[image_id]['url'] for image_id in category_results_data[cat_id_1]['True Positive']]
			category1_false_negatives = [image_data[x[0]]['url'] for x in cat_1_fn_that_went_to_cat_2]
			
			category2_true_positives = 	[image_data[image_id]['url'] for image_id in category_results_data[cat_id_2]['True Positive']]
			category2_false_negatives = [image_data[x[0]]['url'] for x in cat_2_fn_that_went_to_cat_1]
		
		template_data={
			'category1_name' : category_labels[cat_index_1],
			'category1_true_positives' : category1_true_positives,
			'category1_false_negatives' : category1_false_negatives,
			
			'category2_name' : category_labels[cat_index_2],
			'category2_true_positives' : category2_true_positives,
			'category2_false_negatives' : category2_false_negatives,
		}
		
		t = comparison_template.render(**template_data)
		
		page_name = "%s_%s.html" % (cat_id_1,cat_id_2)
		with open(os.path.join(comparison_path, page_name), 'w') as f:
			print >> f, t
		
		comparison_html_links.setdefault(cat_index_1, {})[cat_index_2] = os.path.join(comparison_dir_name, page_name)
		
	##### D3 Confusion Matrix ########	
	# produce some d3 data
	nodes = []
	links = []
	for i, (cat_id, cat_label, cm_row) in enumerate(zip(category_identifiers, category_labels, cm)):
		nodes.append({	'name' : str(cat_label), 
						'group' : 1,
						'index' : i,
						'correct_count' : cm_row[i],
						'id' : cat_id,
					}) 
		for index, col in enumerate(cm_row) :
			links.append({'source' : i, 'target' : index, 'value' : col})
	
	d3_data = {'nodes' : nodes, 'links' : links, 'confusion_matrix' : cm.tolist()}
	max_value = np.max(cm) + 1
	
	recommended_width = 250 + len(category_identifiers) * 15
	recommended_height = recommended_width
	
	template = jinja_env.get_template('confusion_matrix.html')
	template_data = {
		'd3_data' : d3_data,
		'max_value' : max_value,
		'accuracy' : accuracy,
		'comparison_links' : comparison_html_links,
		'detail_links' : details_dir_html_links,
		'recommended_width' : recommended_width,
		'recommended_height' : recommended_height
	}
	cm_html = template.render(**template_data)
	
	with open(os.path.join(output_dir_path, 'confusion_matrix.html'), 'w') as f:
		print >> f, cm_html
	
	#### Top K plot
	# If we have top k data, then lets create a plot
	if top_k_data:
		top_k_x = top_k_data[0]
		top_k_y = top_k_data[1]
		
		fig_edge_length = 10
		fig = plt.figure(figsize=(fig_edge_length, fig_edge_length), dpi=80,)
		ax = fig.add_subplot(111)
		ax.plot(top_k_x, top_k_y)
		ax.set_ylim(0, 1)
		for i,j in zip(top_k_x,top_k_y):
			ax.annotate("%0.3f" % (j,),xy=(i,j))
		ax.hlines(np.arange(.1, 1, .1), top_k_x[0], top_k_x[-1], linestyles='dashed')
		fig.suptitle('Top K')
		plt.savefig(os.path.join(output_dir_path, 'top_k.png'), bbox_inches='tight')
		
	
	######## Main Index Page ##########
	template = jinja_env.get_template('summary.html')
	category_details = {}
	for i, (cat_id, cat_label) in enumerate(zip(category_identifiers, category_labels)):
		
		total_count = category_results_data[cat_id]['Total']
		tp_count = len(category_results_data[cat_id]['True Positive'])
		fp_count = len(category_results_data[cat_id]['False Positive'])
		fn_count = len(category_results_data[cat_id]['False Negative'])
		
		precision = (1.0 * tp_count) / (tp_count + fp_count + np.finfo(float).eps)
		recall = (1.0 * tp_count) / (tp_count + fn_count + np.finfo(float).eps)
		
		category_details[cat_id] = {	'name' : cat_label, 
										'detail_url' : details_dir_html_links[cat_id],
										'precision' : "%0.2f" % (precision,),
										'recall' : 	  "%0.2f" % (recall,),
										'total_count' : total_count,
										'tp_count' : tp_count,
										'fp_count' : fp_count,
										'fn_count' : fn_count
										}
	
	summary_html = template.render(accuracy=accuracy,
								   category_data=category_details,
								   total_image_count=len(ground_truth_identifiers),
								   top_k_path = 'top_k.png' if top_k_data else None
								  )
	
	with open(os.path.join(output_dir_path, 'index.html'), 'w') as f:
		print >> f, summary_html