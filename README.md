# HomeLab Ansible

Even this README is a work in progres..

## What is this?

This ansible project was originally a hodge-podge of playbooks and group/host vars built around roles that catered specifically to our requirements.  Up until this point, I had primarily used salt.  The rapid adoption of ansible (when compared to the somewhat dubious road ahead of Salt) and the ease of initial deployment was appealing.  We also had a need for both one-off, throw-away playbooks and stable, re-usable roles for key infrastructure components - so Ansible seemed to fit nicely.

More than just a home-lab project, this has served as a learning environment where deployment methods have changed significantly or entire services have been forklift-upgraded (and then integrated into the project) to incorporate services or projects we wanted to learn for ourselves or to support professional projects/goals.

## How did this happen?

As we had only recently started to learn and use ansible, some of the roles used in this project were forked and modified as needed.  Some of our own roles were not created with an eye on best-practices. Compounding that issue is the fact that this project spans *many* Ansible, Python, and OS releases; so there is an enormous gap in syntax, patterns, module use (or lack thereof), testing, documentation, etc..

There are entire projects that have been integrated (cephadm-ansible for example). In that case, I only included the modules, preferring instead to create our own roles and playbooks, reassign vars to keep them consistent and to leverage our existing dynamic inventory sources.

But all of these changes over time have introduced so much cardinality to variables alone that maintaining this thing is untenable.  Also trying to implement fixes across several repos while continuing to use (and likely modify) them has proven diffcult and time consuming.

## Fixing this shit-show

We have decided to start over in such a way that we can continue use of our existing project and without worrying about impossible merges and documentation that will be rendered mostly worthless.

Besides the obvious benefits of the aforementioned fixes, starting fresh will bring with it an opportunity to write proper tests, maintain documentation and add additional CI workflows where they have deserately been needed.
