// TODO: Create a simple wrapper to keep all the functionality related to
//       Redcase's dialog windows at the only place, and provide more
//       OOP-like access to show/hide it.
jQuery2(function($) {
	$('#redcase-dialog').keydown(function(event) {
		if (event.keyCode === 13) {
			$(this)
				.parents()
				.find('.ui-dialog-buttonpane button')
				.first()
				.trigger('click');
			return false;
		}
	});
	if (typeof(Redcase) === 'undefined') {
		Redcase = {};
	}
	Redcase = $.extend(
		Redcase, {
			log: LogManager.getLog('redcase'),
			jsCopyToMenuItems: [],
			errorBox: function(errorMessage) {
				$('#redcase-error-message').text(errorMessage);
				$('#redcase-error').dialog({
					modal: true,
					buttons: {
						OK: function() {
							$(this).dialog('close');
						}
					}
				})
			},
    		full: function() {
				this.log.info('Running full update...');
				Redcase.executionSuiteTree.updateList2();
				Redcase.combos.update();
   			},
			initialize: function() {
				// Initialize trees
				if (Redcase.testSuiteTree) {
					Redcase.testSuiteTree.initialize();
				}
				if (Redcase.executionSuiteTree) {
					Redcase.executionSuiteTree.initialize();
				}
				if (Redcase.executionTree) {
					Redcase.executionTree.initialize();
				}
				// Set up event listeners for drag and drop
				$(document).on('dnd_start.vakata', function(e, data) {
					console.log('Drag started', data);
				});
				$(document).on('dnd_stop.vakata', function(e, data) {
					console.log('Drag stopped', data);
				});
			}
		}
	);
	
	// Initialize when the document is ready
	$(document).ready(function() {
		Redcase.initialize();
		
		// Fix for test case icons not showing properly
		setTimeout(function() {
			// Force icon redraw for test cases in management view
			$('#management_test_suite_tree_id .jstree-leaf').each(function() {
				var $node = $(this);
				var nodeId = $node.attr('id');
				var treeRef = $.jstree.reference('#management_test_suite_tree_id');
				if (treeRef && nodeId) {
					var node = treeRef.get_node(nodeId);
					if (node && node.original && node.original.iconCls) {
						// Direct DOM manipulation to set the icon
						$node.find('> a > i.jstree-icon')
							.removeClass()
							.addClass('jstree-icon jstree-themeicon ' + node.original.iconCls);
					}
				}
			});
		}, 1000); // Wait for everything to load
	});
});

