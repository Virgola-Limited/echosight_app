import { Application } from '@hotwired/stimulus'

const application = Application.start()

// Use Vite's import.meta.glob to dynamically import controllers
const controllers = import.meta.glob('./**/*_controller.js')

// Load each controller module dynamically
for (const path in controllers) {
  controllers[path]().then(module => {
    const controllerName = path
      .split('/')
      .pop()
      .replace('_controller.js', '')
      .replace(/_/g, '-')

    application.register(controllerName, module.default)
  })
}

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

export { application }
