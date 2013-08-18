// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Abstract Class that handles Child-Parent communication between [Collection]s.
 *
 * Classes that extend this class need to implement functions modelAdded, modelRemoved and
 * modelChanged ==> What to do when parent adds/removes/changes a model.
 */
abstract class ChildCollection extends Collection {
  Collection parent;

  /**
   * Creates a [ChildCollection] that is child of parent [Collection]
   * and fills it with models from parent collection.
   */
  ChildCollection(Collection parent) : super() {
    this.setParent(parent);
    this.parent.models.forEach((id, model) {
      this.add(model, false);
    });
  }

  /**
   * Sets the parenting [Collection].
   */
  void setParent(Collection parent) {
    this.parent = parent;
    if (this.parent != null) {
      this.parent.events.listen((Map e) {
        switch(e['eventtype']) {
          case 'modelAdded':
            this.modelAdded(e['model']);
            break;
          case 'modelChanged':
            this.modelChanged(e['model'], e['old'], e['new']);
            break;
          case 'modelRemoved':
            this.modelRemoved(e['model']);
            break;
        }
      });
    }
  }

  /**
   * Handles actions that are done when a model is added to parent [Collection].
   */
  void modelAdded(Model model);

  /**
   * Handles actions that are done when a model is removed from parent [Collection].
   */
  void modelRemoved(Model model);

  /**
   * Handles actions that are done when a model is changed in parent [Collection].
   */
  void modelChanged(Model model, Map oldfields, Map newfields);
}