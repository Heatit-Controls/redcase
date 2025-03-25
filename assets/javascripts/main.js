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
	});
});

