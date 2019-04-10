GitOps/Canary CI/CD demo
------------------------

This is a step by step guide on how to set up a GitOps workflow with Istio/flagger and Weave Flux. GitOps is a way to do Continuous Delivery, it works by using Git as a source of truth for declarative infrastructure and workloads. In practice this means using git push instead of kubectl create/apply or helm install/upgrade.
 
Requirements
------------

  * GCP Project;
  * CircleCI and GitHub accounts;
  * helm, terraform, kubectl and git binaries.

Spin up the environment
-----------------------

Clone the repo on your PC, and then go to the terraform folder

```bash
git clone git@github.com/skhedim/demo-gitops
cd demo-gitops/terraform
```

Alternatively, you can use Composer:

```bash
$ composer create-project symfony/symfony-demo my_project
```

Usage
-----

There's no need to configure anything to run the application. If you have
installed the [Symfony client][4] binary, run this command to run the built-in
web server and access the application in your browser at <http://localhost:8000>:

```bash
$ cd my_project/
$ symfony serve
```

If you don't have the Symfony client installed, run `php bin/console server:run`.
Alternatively, you can [configure a web server][3] like Nginx or Apache to run
the application.

Tests
-----

Execute this command to run tests:

```bash
$ cd my_project/
$ ./bin/phpunit
```

[1]: https://symfony.com/doc/current/best_practices/index.html
[2]: https://symfony.com/doc/current/reference/requirements.html
[3]: https://symfony.com/doc/current/cookbook/configuration/web_server_configuration.html
[4]: https://symfony.com/download