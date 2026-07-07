#Guideline for Rails Based App

* Use rails cli whenever possible to generate new app or scafold the code.
* Use Rails version should be later than 8. Stay close to Rails 8 conventions.
* Use SQLite database unless user mentions to usesomething else
* Use tailwindcss for CSS
* When creating a business process or workflow, think about business processes related to Active Record Models as a state machine that can benefit from fosm-rails gem (which can be isntalled with ```gem install fosm-rails``` ). FOSM approach gives your Rails models a formal, enforced lifecycle with states, events, guards, side-effects, and an AI agent interface. Business rules live in the model, not scattered across callbacks.
* Write rspec tests before writing code. Follow test driven development approach.
* The application must be developed with mindset of 12-factor App.
* Once the feature is fully built out, use the agent browser tool to test the flow by starting a recording session. Place the recordings and screenshots in /workspace/workfeed' (create if it does not exists)


## When asked to create a Rails application from RunwayLite or Inloop Studio's best practices. Use the existing Rails Application template at https://github.com/inloopstudio-team/RunwayLite/archive/refs/heads/master.zip , download it, unzip and rename it to the project name and proceed. Ensure to use .agents dir for the context.
