# Changelog

This document lists changes for each release.

## Upcoming

## v0.2.0

* Children elements are now created after computing changed props from
  selectors. This is more efficient in cases where children will be removed or
  computed separately. For example, deleting children in Changes or wrapping a
  template in a component.
* Children with the same name are now wrapped in a fragment with that name.
  This allows you to remove/replace all children with a given name.
* Changed signature of ChangesCallback. It now takes a template instance and
  returns a set of changes.
  * The old signature provided `props` and `children`. Props was useless since
    only non-default props were defined. Children were useless since they were
    Roact elements not meant for reading.
  * The new signature provides the instance being used for the template. This
    allows you to access the props and children of the instance. You now return
    a list of changes instead of mutating the props and children.
* Some error messages are now more clear and provide direction on the correct
  way to do things.
* There are more typechecks on the user-facing part of the library.

## v0.1.0

Initial release