var RedcaseTestSuiteTree = function($) {

	var self = this;

	this.tree = null;

	var caseItems;

	var specialSuiteItems;

	var suiteItems;

	var commonItems;

	this.initialize = function() {
		prepareContextItems();
		build();
		
		// Add a formatter to make sure icons are updated after initialization
		setTimeout(function() {
			$('#management_test_suite_tree_id .jstree-node').each(function() {
				var nodeId = $(this).attr('id');
				if (nodeId) {
					var node = self.tree.get_node(nodeId);
					if (node && node.original && node.original.type === 'case' && node.original.iconCls) {
						self.tree.set_icon(node, node.original.iconCls);
						// Force a redraw of the node
						$(this).find('> a > i').removeClass().addClass(node.original.iconCls);
					}
				}
			});
		}, 500);
	};

	this.getSelectionType = function(tree) {
		var selectionType = -1;
		var selection = tree.get_selected(true);
		for (var i = 0; i < selection.length; i++) {
			if (selectionType !== 2) {
				if (selection[i].type === 'case') {
					if (selectionType === 1) {
						selectionType = 2;
					} else {
						selectionType = 0;
					}
				} else if (selection[i].type === 'suite') {
					if (selectionType === 0) {
						selectionType = 2;
					} else {
						selectionType = 1;
					}
				}
			}
			if ((selection[i].parents.length === 1)
				|| (selection[i].text === '.Obsolete')
				|| (selection[i].text === '.Unsorted')
			) {
				selectionType = (selection.length === 1)
					? 3
					: 4;
				break;
			}
		}
		return selectionType;
	};

	var checkCallback = function(
		operation,
		node,
		nodeParent,
		node_position,
		more
	) {
		// Operation can be 'create_node', 'rename_node', 'delete_node',
		// 'move_node' or 'copy_node'.
		var isOK = true;
		if (operation === "copy_node") {
			if (more.ref !== undefined) {
				isOK = (this.get_node(node.parent) != nodeParent);
			}
		}
		return isOK;
	};

	var isDraggable = function(nodes) {
		// Make sure the user can't drag the root node, "default" nodes,
		// the "unsorted" node, and disabled nodes.
		for (var i = 0; i < nodes.length; i++) {
			if ((nodes[i].parents.length < 2)
				|| (nodes[i].type === 'default')
				|| (nodes[i].text === '.Unsorted')
				|| (nodes[i].state.disabled === true)
			) {
				return false;
			}
		}
		return true;
	};

	var moveTestCase = function(
		newNode,
		orgNode,
		newInstance,
		oldInstance
	) {
		newNode.original = orgNode.original;
		var apiParms = $.extend(
			{},
			Redcase.api.testCase.update(orgNode.original.issue_id), {
				params: {
					parent_id: newInstance
						.get_node(newNode.parent)
						.original
						.suite_id
				},
				success: function() {
					oldInstance.delete_node(orgNode);
				},
				error: function() {
					newInstance.delete_node(newNode);
				},
				errorMessage: (
					"Test case '" + orgNode.text + "' can't be moved"
				)
			}
		);
		Redcase.api.apiCall(apiParms);
	};

	var moveTestSuite = function(
		newNode,
		orgNode,
		newInstance,
		oldInstance
	) {
		newNode.original = orgNode.original;
		var apiParms = $.extend(
			{},
			Redcase.api.testSuite.update(orgNode.original.suite_id), {
				params: {
					parent_id: newInstance
						.get_node(newNode.parent)
						.original
						.suite_id
				},
				success: function () {
					oldInstance.delete_node(orgNode);
				},
				error: function () {
					newInstance.delete_node(newNode);
				},
				errorMessage: (
					"Test suite '" + orgNode.text + "' can't be moved"
				)
			}
		);
		Redcase.api.apiCall(apiParms);
	};

	var onCopy = function(event, object) {
		// Fields: is_foreign, is_multi, new_instance, node,old_instance,
		//         old_parent (ID), old_position (index), original (node),
		//         parent (id), position (index (altid 0?))
		// Internal drag + drop
		if (object.old_instance === object.new_instance) {
			switch (object.original.type) {
			case 'case':
				moveTestCase(
					object.node,
					object.original,
					object.new_instance,
					object.old_instance
				);
				break;
			case 'suite':
				moveTestSuite(
					object.node,
					object.original,
					object.new_instance,
					object.old_instance
				);
				break;
			}
		}
	};

	var contextCopyTo = function(params) {
		var node = self.tree.get_node(params.reference);
		var apiParms = $.extend(
			{},
			Redcase.api.testCase.copy(node.original.issue_id), {
				params : {
					dest_project: params.item.id
				},
				errorMessage: ("Can't copy '" + node.text + "'")
			}
		);
		Redcase.api.apiCall(apiParms);
	};

	var prepareContextItems = function() {
		var tmpObj = {};
		var copyItems = {};
		for (var i = 0; i < Redcase.jsCopyToMenuItems.length; i++) {
			tmpObj['keyfor_' + Redcase.jsCopyToMenuItems[i].id] = {
				label: Redcase.jsCopyToMenuItems[i].text,
				id: Redcase.jsCopyToMenuItems[i].id,
				action: contextCopyTo
			};
			$.extend(copyItems, tmpObj);
		}
		caseItems = {
			viewCase: {
				label: 'View',
				action: viewCase
			},
			copyCase: {
				label: 'Copy to',
				submenu: copyItems
			}
		};
		specialSuiteItems = {
			addSuite: {
				label: 'Add suite',
				action: addSuite
			}
		};
		suiteItems = {
			renameSuite: {
				label: 'Rename',
				action: renameSuite
			}
		};
		commonItems = {
			deleteItem: {
				label: 'Delete',
				action: deleteItem
			}
		};
	};

	var deleteCase = function(node) {
		var apiParms = $.extend(
			{},
			Redcase.api.testCase.update(node.original.issue_id), {
				params: {
					obsolesce: true
				},
				success: function() {
					var org = $.extend({}, node.original);
					self.tree.delete_node(node);
					var newId = self.tree.create_node(
						self.tree.get_node('.Obsolete'),
						org
					);
					console.log('newId = ' + newId);
				},
				errorMessage: (
					"Test case '" + node.text + "' can't be deleted"
				)
			}
		);
		Redcase.api.apiCall(apiParms);
	};

	var deleteSuite = function(node) {
		if ((node.parents.length > 1)
			&& (node.text !== '.Unsorted')
			&& (node.text !== '.Obsolete')
		) {
			var apiParms = $.extend(
				{},
				Redcase.api.testSuite.destroy(node.original.suite_id), {
					success: function () {
						self.tree.delete_node(node);
					},
					errorMessage: (
						"Execution suite '"
						+ node.text
						+ "' can't be deleted"
					)
				}
			);
			Redcase.api.apiCall(apiParms);
		} else {
			// Error, can't delete root node.
			console.log('Tried to delete suite: ' + node.text);
		}
	};

	var deleteItem = function(params) {
		var node = self.tree.get_node(params.reference);
		if (node.type === 'case') {
			deleteCase(node);
		} else {
			deleteSuite(node);
		}
	};

	var addSuite = function(params) {
		try {
			var node = self.tree.get_node(params.reference);
			if (!node) {
				console.error('Node not found for reference:', params.reference);
				return;
			}
			
			console.log('Adding suite to node:', node);
			
			// Ensure the dialog element exists and is properly initialized
			var $dialog = $('#redcase-dialog');
			if ($dialog.length === 0) {
				console.error('Dialog element not found');
				$('body').append('<div id="redcase-dialog"><input type="text" id="redcase-dialog-value" style="width: 95%;" /></div>');
				$dialog = $('#redcase-dialog');
			}
			
			// Reset the dialog input field
			$('#redcase-dialog-value').val('');
			
			// Use direct jQuery UI dialog method
			try {
				$dialog.dialog({
					title: 'New test suite name',
					modal: true,
					resizable: false,
					width: 300,
					open: function() {
						console.log('Dialog opened');
						// Focus the input field
						$('#redcase-dialog-value').focus();
					},
					buttons: [
						{
							text: "OK",
							click: function() {
								var name = $('#redcase-dialog-value').val();
								if (name.trim() === '') {
									alert('Test suite name cannot be empty');
									return;
								}
								
								console.log('Creating new suite with name:', name);
								
								var apiParms = $.extend(
									{},
									Redcase.api.testSuite.create(), {
										params: {
											name: name,
											parent_id: node.original.suite_id
										},
										success: function(newNode) {
											console.log('New node created:', newNode);
											self.tree.create_node(node, newNode);
											self.tree.open_node(node);
										},
										errorMessage: (
											"Test suite '"
											+ name
											+ "' can't be created"
										),
										complete: function() {
											$dialog.dialog('close');
										}
									}
								);
								Redcase.api.apiCall(apiParms);
							}
						},
						{
							text: "Cancel",
							click: function() {
								$(this).dialog('close');
							}
						}
					]
				});
				
				console.log('Dialog initialization successful');
			} catch (dialogError) {
				console.error('Error initializing dialog:', dialogError);
				
				// Fallback to simple prompt if dialog fails
				var name = prompt('Enter new test suite name:');
				if (name && name.trim() !== '') {
					var apiParms = $.extend(
						{},
						Redcase.api.testSuite.create(), {
							params: {
								name: name,
								parent_id: node.original.suite_id
							},
							success: function(newNode) {
								self.tree.create_node(node, newNode);
								self.tree.open_node(node);
							},
							errorMessage: (
								"Test suite '"
								+ name
								+ "' can't be created"
							)
						}
					);
					Redcase.api.apiCall(apiParms);
				}
			}
		} catch (error) {
			console.error('Error in addSuite function:', error);
		}
	};

	var renameSuite = function(params) {
		var node = self.tree.get_node(params.reference);
		if ((node.parents.length > 1)
			&& (node.text !== '.Unsorted')
			&& (node.text !== '.Obsolete')
		) {
			self.tree.edit(node);
		}
	};

	var viewCase = function(params) {
		try {
			console.log('View case called with params:', params);
			var node = self.tree.get_node(params.reference);
			
			if (!node) {
				console.error('Node not found for reference:', params.reference);
				return;
			}
			
			console.log('Viewing test case node:', node);
			
			if (!node.original || !node.original.issue_id) {
				console.error('No issue ID found for node:', node);
				return;
			}
			
			var issueId = node.original.issue_id;
			var url = '../../issues/' + issueId;
			console.log('Opening URL:', url);
			
			// Open in a new window/tab
			window.open(url, '_blank');
		} catch (error) {
			console.error('Error in viewCase function:', error);
			
			// Try to extract issue ID from node ID as fallback
			if (params.reference) {
				var matches = params.reference.match(/issue_(\d+)/);
				if (matches && matches[1]) {
					var issueId = matches[1];
					console.log('Fallback: Opening issue ID from node ID:', issueId);
					window.open('../../issues/' + issueId, '_blank');
				}
			}
		}
	};

	var build = function() {
		console.log('Building test suite tree...');
		try {
			// Create jstree and store the reference
			$('#management_test_suite_tree_id').jstree({
				core: {
					check_callback: checkCallback,
					data: {
						type: 'GET',
						url: Redcase.api.context + Redcase.api.testSuite.index().method,
						dataFilter: function(data) {
							// Process the data before jstree processes it
							var json = JSON.parse(data);
							console.log('Data received from server:', json);
							return JSON.stringify(json);
						}
					},
					themes: {
						icons: true
					}
				},
				plugins: ['dnd', 'types', 'contextmenu'],
				types: {
					'#': {
						valid_children: ['root']
					},
					root: {
						valid_children: ['suite', 'case']
					},
					suite: {
						valid_children: ['suite', 'case']
					},
					'default': {
						valid_children: []
					},
					'case': {
						valid_children: []
					}
				},
				contextmenu: {
					items: function(node) {
						var items = {};
						if (node.type === 'case') {
							$.extend(items, caseItems);
							if ((node.parents.length > 1)
								&& (node.parents[1] !== 'Default')
								&& (node.text !== '.Obsolete')
							) {
								$.extend(items, commonItems);
							}
						} else if (node.type === 'suite') {
							if ((node.parents.length > 1)
								&& (node.text !== '.Obsolete')
								&& (node.text !== '.Unsorted')
							) {
								$.extend(items, suiteItems);
								$.extend(items, commonItems);
							}
							$.extend(items, specialSuiteItems);
						}
						return items;
					}
				},
				dnd: {
					always_copy: true,
					drag_selection: true,
					is_draggable: isDraggable,
					check_while_dragging: true
				}
			});

			// Properly get the tree reference - must use jQuery(ID).jstree(true) format
			self.tree = jQuery2('#management_test_suite_tree_id').jstree(true);
			
			// Bind events using jQuery directly to avoid "tree.on is not a function" error
			var treeElement = $('#management_test_suite_tree_id');
			
			// Bind copy node event
			treeElement.on('copy_node.jstree', onCopy);
			
			// Bind loaded event to handle icons
			treeElement.on('loaded.jstree', function(e, data) {
				setTimeout(function() {
					// After tree is loaded, set icons for test cases based on iconCls
					treeElement.find('.jstree-leaf').each(function() {
						var nodeId = $(this).attr('id');
						if (nodeId) {
							var node = self.tree.get_node(nodeId);
							if (node && node.original && node.original.iconCls) {
								self.tree.set_icon(node, node.original.iconCls);
							}
						}
					});
				}, 100);
			});
			
			// Bind refresh event
			treeElement.on('refresh.jstree', function() {
				setTimeout(function() {
					treeElement.find('.jstree-leaf').each(function() {
						var nodeId = $(this).attr('id');
						if (nodeId) {
							var node = self.tree.get_node(nodeId);
							if (node && node.original && node.original.iconCls) {
								self.tree.set_icon(node, node.original.iconCls);
							}
						}
					});
				}, 100);
			});
			
			// Bind open node event
			treeElement.on('after_open.jstree', function(e, data) {
				if (data.node && data.node.children) {
					$(data.node.children).each(function(i, nodeId) {
						var childNode = self.tree.get_node(nodeId);
						if (childNode && childNode.type === 'case' && childNode.original && childNode.original.iconCls) {
							self.tree.set_icon(childNode, childNode.original.iconCls);
						}
					});
				}
			});
		} catch (error) {
			console.error('Error during tree initialization:', error);
		}
	};
};

jQuery2(function($) {
	if (typeof(Redcase) === 'undefined') {
		Redcase = {};
	}
	if (Redcase.testSuiteTree) {
		return;
	}
	Redcase.testSuiteTree = new RedcaseTestSuiteTree($);
});
