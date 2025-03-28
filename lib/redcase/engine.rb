module Redcase
  class Engine < ::Rails::Engine
    initializer 'redcase.assets' do |app|
      app.config.assets.precompile += %w(
        redcase/testSuiteTree.js
        redcase/executionSuiteTree.js
        redcase/executionTree.js
        javascripts/jstree/themes/default/style.min.css
      )
      
      # Register plugin assets path
      app.config.assets.paths << root.join('assets', 'javascripts')
      app.config.assets.paths << root.join('assets', 'stylesheets')
      app.config.assets.paths << root.join('assets', 'images')
      app.config.assets.paths << root.join('assets', 'fonts')
    end
  end
end 