var RedcaseExecutionSuiteTree = function($) {

	var self = this;
	this.tree = null;

	var caseItems;

	var specialSuiteItems;

	var suiteItems;

	var commonItems;

	this.updateList2 = function() {
		var apiParms = $.extend(
			{},
			Redcase.api.executionSuite.index(), {
				success: function(data, textStatus, request) {
					$('#execution_settings_id').html(data);
					Redcase.executionTree.refresh();
				},
				errorMessage : "Couldn't load execution list"
			}
		);
		Redcase.api.apiCall(apiParms);
	};

	var saveExecSuiteClick = function(event) {
		renameSuite(
			$('#list_id').val(),
			$('#list_name').val(),
			function(data, textStatus, request) {
				$('#list_id option:selected').text($('#list_name').val());
			},
			function() {
				self.tree.refresh();
				Redcase.full();
			}
		);
		event.preventDefault();
	};

	var createExecSuiteClick = function(event) {
		addSuite(
			undefined,
			$('#list_name').val(),
			function(data, textStatus, request) {
				$('#list_id').append(
					$('<option>', {
						value: data.suite_id
					}).text($('#list_name').val())
				);
				$('#list_id').val(data.suite_id);
			},
			function() {
				self.tree.refresh();
				Redcase.full();
			}
		);
		event.preventDefault();
	};

	var destroyExecSuiteClick = function(event) {
		deleteSuite(
			$('#list_id').val(),
			$('#list_id option:selected').text(),
			function(data, textStatus, request) {
				$("#list_id option:selected").remove();
				$('#list_name').val(
					$("#list_id option:selected").text()
				);
				self.tree.refresh();
				Redcase.full();
			}
		);
		event.preventDefault();
	};

	var checkCallback = function(
		operation,
		node,
		nodeParent,
		nodePosition,
		more
	) {
		// Operation can be 'create_node', 'rename_node',
		// 'delete_node', 'move_node' or 'copy_node'.
		var isOK = true;
		if ((operation === "copy_node") && (more.ref !== undefined)) {
			var sameNode = this.get_node(node);
			isOK = (this.get_node(node.parent) != nodeParent)
				&& (!sameNode || (sameNode === node))
				&& (node.original.type == 'case');
			if (!isOK && sameNode) {
				this.select_node(sameNode);
			}
		}
		return isOK;
	};

	var isDraggable = function(nodes) {
		// Make sure the user can't drag the root node
		for (var i = 0; i < nodes.length; i++) {
			if (nodes[i].parents.length < 2) {
				return false;
			}
		}
		return true;
	};

	var prepareContextItems = function() {
		caseItems = {};
		specialSuiteItems = {
			addSuite: {
				label: 'Add suite',
				action: addSuiteDialog
			}
		};
		suiteItems = {
			renameSuite: {
				label: 'Rename suite',
				action: renameSuiteDialog
			}
		};
		commonItems = {
			deleteItem: {
				label: 'Delete',
				action: deleteItem
			}
		};
	};

	var refresh = function() {
		$('#list_name').val(
			$('#list_id').children(':selected').text()
		);
		self.tree.refresh();
	};

	var addSuite = function(
		parentId,
		name,
		successCallback,
		completeCallback
	) {
		var apiParms = $.extend(
			{},
			Redcase.api.executionSuite.create(), {
				params: {
					name: name,
					parent_id: parentId
				},
				success: successCallback,
				errorMessage: (
					"Execution suite '"
					+ name
					+ "' can't be created"
				),
				complete: completeCallback
			}
		);
		Redcase.api.apiCall(apiParms);
	};

	var addSuiteDialog = function(params) {
		var node = self.tree.get_node(params.reference);
		$('#redcase-dialog').dialog({
			title: 'Creating execution suite',
			modal: true,
			resizable: false,
			buttons: {
				OK: function() {
					var name = $('#redcase-dialog-value').val();
					addSuite(
						node.original.suite_id,
						name,
						function(newNode) {
							self.tree.create_node(
								node,
								newNode
							);
							Redcase.full();
						},
						function() {
							$('#redcase-dialog').dialog('close');
						}
					);
				}
			}
		});
	};

	var deleteSuite = function(
		suiteId,
		name,
		successCallback
	) {
		var apiParms = $.extend(
			{},
			Redcase.api.executionSuite.destroy(suiteId), {
				success: successCallback,
				errorMessage: (
					"Execution suite '"
					+ name
					+ "' can't be deleted"
				)
			}
		);
		Redcase.api.apiCall(apiParms);
	};

	var deleteSuiteNode = function(node) {
		if (node.parents.length > 1) {
			deleteSuite(
				node.original.suite_id,
				node.text,
				function() {
					self.tree.delete_node(node);
					Redcase.full();
				}
			);
		} else {
			// Error, can't delete root node.
			console.log('Tried to delete suite: ' + node.text);
		}
	};

	var deleteCase = function (node) {
		var apiParms = $.extend(
			{},
			Redcase.api.testCase.update(node.original.issue_id), {
				params: {
					remove_from_exec_id: self.tree
						.get_node(node.parent)
						.original
						.suite_id
				},
				success: function() {
					self.tree.delete_node(node);
					Redcase.full();
				},
				errorMessage: (
					"Test case '"
					+ node.text
					+ "' can't be deleted"
				)
			}
		);
		Redcase.api.apiCall(apiParms);
	};

	var deleteItem = function(params) {
		var selected = self.tree.get_selected(true);
		for (var i = 0; i < selected.length; i++) {
			if (selected[i].type === 'case') {
				deleteCase(selected[i]);
			} else {
				deleteSuiteNode(selected[i]);
			}
		}
	};

	var renameSuite = function(
		suiteId,
		name,
		successCallback,
		completeCallback
	) {
		var apiParms = $.extend(
			{},
			Redcase.api.executionSuite.update(suiteId), {
				params: {
					new_name: name
				},
				success: successCallback,
				errorMessage: (
					"Execution suite '"
					+ name
					+ "' can't be renamed"
				),
				complete: completeCallback
			}
		);
		Redcase.api.apiCall(apiParms);
	};

	var renameSuiteDialog = function(params) {
		var node = self.tree.get_node(params.reference);
		$('#redcase-dialog').dialog({
			title: 'Renaming execution suite',
			modal: true,
			resizable: false,
			buttons: {
				OK: function() {
					var name = $('#redcase-dialog-value').val();
					renameSuite(
						node.original.suite_id,
						name,
						function() {
							self.tree.set_text(node, name);
							Redcase.full();
						},
						function() {
							$('#redcase-dialog').dialog('close')
						}
					);
				}
			}
		});
	};

	var getItems = function() {
		var items = {};
		var selectionType = Redcase.testSuiteTree.getSelectionType(self.tree);
		if (selectionType < 3) {
			items = $.extend(items, commonItems);
		}
		// Testcase
		if (selectionType === 0) {
			$.extend(items, caseItems);
		}
		// Testsuite
		if (selectionType === 1) {
			$.extend(items, suiteItems);
		}
		// Testsuite or Special
		if ((selectionType === 1) || (selectionType === 3)) {
			$.extend(items, specialSuiteItems);
		}
		return items;
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
					source_exec_id: oldInstance
						.get_node(orgNode.parent)
						.original
						.suite_id,
					dest_exec_id: newInstance
						.get_node(newNode.parent)
						.original
						.suite_id
				},
				success: function() {
					oldInstance.delete_node(orgNode);
					Redcase.full();
				},
				error: function() {
					newInstance.delete_node(newNode);
				},
				errorMessage: (
					"Test case '"
					+ orgNode.text
					+ "' can't be moved"
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
			Redcase.api.executionSuite.update(
				orgNode.original.suite_id
			), {
				params: {
					parent_id: newInstance
						.get_node(newNode.parent)
						.original
						.suite_id
				},
				success: function() {
					oldInstance.delete_node(orgNode);
					Redcase.full();
				},
				error: function() {
					newInstance.delete_node(newNode);
				},
				errorMessage: (
					"Test suite '"
					+ orgNode.text
					+ "' can't be moved"
				)
			}
		);
		Redcase.api.apiCall(apiParms);
	};

	var copyTestCase = function(
		newNode,
		orgNode,
		newInstance,
		oldInstance
	) {
		if (orgNode.original.status.name.toLowerCase() === 'in progress') {
			newNode.original = orgNode.original;
			newInstance.set_id(newNode, orgNode.id);
			var apiParms = $.extend(
				{},
				Redcase.api.testCase.update(orgNode.original.issue_id), {
					params: {
						dest_exec_id: newInstance
							.get_node(newNode.parent)
							.original
							.suite_id
					},
					success: function(data) {
						if (data.success === true) {
							Redcase.full();
						} else {
							newInstance.delete_node(newNode);
							Redcase.errorBox(
								"Test case '"
								+ orgNode.text
								+ "' can't be added"
							);
						}
					},
					error: function() {
						newInstance.delete_node(newNode);
					},
					errorMessage: (
						"Test case '" + orgNode.text + "' can't be added"
					)
				}
			);
			Redcase.api.apiCall(apiParms);
		} else {
			newInstance.delete_node(newNode);
		}
	};

	var onCopy = function(event, params) {
		// Make sure we have a valid node and parameters
		try {
			console.log('onCopy called with params:', params);
			
			// Ensure we have the tree instance
			var currentTree = self.tree || tree;
			if (!currentTree) {
				console.error('No tree instance available in onCopy function');
				return;
			}
			
			// Check if we have valid node and parent information
			if (!params.node || !params.parent) {
				console.error('Missing node or parent in copy_node event:', params);
				return;
			}
			
			// Get the issue ID from the node
			var issueId;
			
			// First try to get it from the original node's data
			if (params.original && params.original.node && params.original.node.original && params.original.node.original.issue_id) {
				issueId = params.original.node.original.issue_id;
			} 
			// If not found, try to extract from the node ID
			else if (params.node.id && params.node.id.indexOf('issue_') === 0) {
				issueId = params.node.id.split('_')[1];
			}
			// If still not found, try the node's original data
			else if (params.node.original && params.node.original.issue_id) {
				issueId = params.node.original.issue_id;
			}
			
			// If we couldn't find an issue ID, log an error and stop
			if (!issueId) {
				console.error('Could not extract issue ID from node:', params.node);
				return;
			}
			
			// Get the parent ID (destination execution suite ID)
			var parentId;
			
			// First try to extract from the parent ID string
			if (typeof params.parent === 'string' && params.parent.indexOf('suite_') === 0) {
				parentId = params.parent.split('_')[1];
			} 
			// If not found, try to get the parent node and extract suite_id
			else {
				var parentNode = currentTree.get_node(params.parent);
				if (parentNode && parentNode.original && parentNode.original.suite_id) {
					parentId = parentNode.original.suite_id;
				}
			}
			
			// If we couldn't find a parent ID, log an error and stop
			if (!parentId) {
				console.error('Could not extract parent ID from:', params.parent);
				currentTree.delete_node(params.node);
				return;
			}
			
			console.log('Adding test case ' + issueId + ' to execution suite ' + parentId);
			
			// Now make the API call to add the test case to the execution suite
			var apiParms = $.extend({}, 
				Redcase.api.testCase.update(issueId), {
					params: {
						add_to_exec_id: parentId
					},
					success: function() {
						// Set the node's original data to include the issue_id
						if (params.original && params.original.node && params.original.node.original) {
							params.node.original = params.original.node.original;
						}
						Redcase.full();
					},
					error: function() {
						currentTree.delete_node(params.node);
					},
					errorMessage: "Test case can't be added to execution list"
				}
			);
			Redcase.api.apiCall(apiParms);
		} catch (error) {
			console.error('Error in onCopy function:', error);
			// Try to clean up the node if possible
			if (params.node && currentTree) {
				try {
					currentTree.delete_node(params.node);
				} catch (e) {
					console.error('Error cleaning up node:', e);
				}
			}
		}
	};

	var nodeSelected = function(e, data) {
		// Empty function to prevent errors
		console.log('Node selected:', data.node);
	};

	var build = function() {
		prepareContextItems();
		var jstree = $('#management_execution_suite_tree_id').jstree({
			core: {
				animation: 0,
				check_callback: checkCallback,
				force_text: true,
				themes: {
					icons: true
				},
				data: {
					type: 'GET',
					url: function() {
						return Redcase.api.context
							+ Redcase.api.executionSuite.index(
								$('#list_id').val()
							).method;
					}
				}
			},
			plugins: ['dnd', 'types', 'contextmenu'],
			types: {
				'#': {
					valid_children: ['root']
				},
				'root': {
					valid_children: ['suite', 'case']
				},
				'suite': {
					valid_children: ['suite', 'case']
				},
				'case': {
					valid_children: []
				},
				'default': {
					valid_children: []
				}
			},
			contextmenu: {
				items: function(obj) {
					var items = {};
					if (obj.type === 'case') {
						$.extend(items, caseItems);
					} else if (obj.type === 'suite') {
						$.extend(items, suiteItems);
						if (obj.parents.length < 2) {
							$.extend(items, specialSuiteItems);
						}
						$.extend(items, commonItems);
					}
					return items;
				}
			},
			dnd: {
				always_copy: true,
				inside_pos: 'last',
				is_draggable: isDraggable,
				check_while_dragging: true
			}
		});
		
		console.log('jstree initialization complete');
		
		// Get the jstree instance and store it
		var treeInstance = $('#management_execution_suite_tree_id').jstree(true);
		console.log('Tree instance obtained:', treeInstance);
		
		// Attach events using jQuery, not the tree instance
		$('#management_execution_suite_tree_id').on('copy_node.jstree', onCopy);
		$('#management_execution_suite_tree_id').on('select_node.jstree', nodeSelected);
		
		// Store the tree instance in both places for compatibility
		self.tree = treeInstance;
		tree = treeInstance;
		
		console.log('Tree instance assigned to:', self.tree);
	};

	this.initialize = function() {
		prepareContextItems();
		build();
		
		// Setup event handlers for buttons
		$('#btn_save_exec_suite').click(saveExecSuiteClick);
		$('#btn_create_exec_suite').click(createExecSuiteClick);
		$('#btn_destroy_exec_suite').click(destroyExecSuiteClick);
		
		// Handle list change
		$('#list_id').change(function() {
			$('#list_name').val($(this).children(':selected').text());
			refresh();
		});
		
		console.log('ExecutionSuiteTree initialized');
	};

};

jQuery2(function($) {
	if (typeof(Redcase) === 'undefined') {
		Redcase = {};
	}
	if (Redcase.executionSuiteTree) {
		return;
	}
	Redcase.executionSuiteTree = new RedcaseExecutionSuiteTree($);
});

