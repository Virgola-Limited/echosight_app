guard :rspec, cmd: 'rspec -f doc' do
  # Watch for changes in spec files themselves
  watch(%r{^spec/.+_spec\.rb$})

  # Rails specific
  watch(%r{^app/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
  watch('app/controllers/application_controller.rb')  { "spec/controllers" }
  watch(%r{^app/controllers/(.+)_controller\.rb$})    { |m| "spec/controllers/#{m[1]}_controller_spec.rb" }
  watch(%r{^app/services/(.+)\.rb$})                  { |m| "spec/services/#{m[1]}_spec.rb" }
  watch(%r{^app/jobs/(.+)\.rb$})                      { |m| "spec/jobs/#{m[1]}_spec.rb" }
  watch(%r{^app/mailers/(.+)\.rb$})                   { |m| "spec/mailers/#{m[1]}_spec.rb" }

  # Watch for changes in non-spec files that don't follow the app/name.rb convention
  watch(%r{^lib/(.+)\.rb$})                           { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^services/(.+)\.rb$})                      { |m| "spec/services/#{m[1]}_spec.rb" }

  # Watch for changes in config files
  watch(%r{^config/.+\.rb$})                          { "spec" }
  watch('config/routes.rb')                           { "spec/routing" }
  watch('config/initializers/devise.rb')              { "spec/controllers" }
  watch('config/application.rb')                      { "spec" }

  # Watch for changes in spec helper files
  watch('spec/spec_helper.rb')                        { "spec" }
  watch('spec/rails_helper.rb')                       { "spec" }
  watch('spec/support/**/*.rb')                       { "spec" }

  # Watch for fixture changes
  # watch(%r{^spec/fixtures/(.+)\.yml$})                { "spec/models" }
  watch('spec/factories.rb')                          { "spec" }

  # Watch for changes in JavaScript files
  watch(%r{^app/javascript/.+\.(js|ts|vue|jsx|tsx)$}) { "spec/system" }
  watch(%r{^app/helpers/.+\.rb$})                     { "spec/helpers" }

  # Watch for changes in view files
  # watch(%r{^app/views/(.+)/.*\.(erb|haml|slim)$})     { |m| "spec/features/#{m[1]}_spec.rb" }

  # Frontend assets
  # watch(%r{^app/assets/stylesheets/.+\.(css|scss)$})  { "spec/system" }
  # watch(%r{^app/assets/javascripts/.+\.(js|jsx)$})    { "spec/system" }
end
