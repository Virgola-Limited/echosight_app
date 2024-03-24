describe('Login user', function() {

  it.only('attempts to login with invalid email', function() {
    cy.visit(Cypress.env('login_path'));
    cy.get('input[name="email"]').type('invalid@example.com');
    cy.get('input[name="password"]').type('password');
    cy.get('form').submit();
    cy.contains('Invalid email or password').should('be.visible');
  });

  it('attempts to login with invalid password', function() {
    // Use cy.appFactories to create a user with a known email and password
    cy.appFactories([
      ['create', 'user', { email: 'user@example.com', password: 'correctpassword' }]
    ]);

    cy.visit(Cypress.env('login_path'));
    cy.get('input[name="email"]').type('user@example.com');
    cy.get('input[name="password"]').type('wrongpassword');
    cy.get('form').submit();
    cy.contains('Invalid email or password').should('be.visible');
  });

  it('attempts to login with unconfirmed email', function() {
    // Create an unconfirmed user using the :unconfirmed trait
    cy.appFactories([
      ['create', 'user', 'unconfirmed', { email: 'unconfirmed@example.com', password: 'password' }]
    ]);

    cy.visit(Cypress.env('login_path'));
    cy.get('input[name="email"]').type('unconfirmed@example.com');
    cy.get('input[name="password"]').type('password');
    cy.get('form').submit();
    cy.contains('You have to confirm your email address before continuing').should('be.visible');
  });

  it('successfully logs in with valid credentials', function() {
    // Create a confirmed user
    cy.appFactories([
      ['create', 'user', { email: 'confirmed@example.com', password: 'validpassword' }]
    ]);

    cy.visit(Cypress.env('login_path'));
    cy.get('input[name="email"]').type('confirmed@example.com');
    cy.get('input[name="password"]').type('validpassword');
    cy.get('form').submit();
    cy.url().should('include', '/dashboard');
    cy.get('.welcome-message').should('contain', 'Welcome');
  });

});
