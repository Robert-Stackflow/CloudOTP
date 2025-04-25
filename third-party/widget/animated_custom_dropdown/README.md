# Custom Dropdown

**Custom Dropdown** package lets you add customizable animated dropdown widget.

[![pub.dev](https://img.shields.io/pub/v/animated_custom_dropdown.svg?style=flat?logo=dart)](https://pub.dev/packages/animated_custom_dropdown)
[![likes](https://img.shields.io/pub/likes/animated_custom_dropdown)](https://pub.dev/packages/animated_custom_dropdown/score)
[![popularity](https://img.shields.io/pub/popularity/animated_custom_dropdown)](https://pub.dev/packages/animated_custom_dropdown/score)
[![pub points](https://img.shields.io/pub/points/animated_custom_dropdown)](https://pub.dev/packages/animated_custom_dropdown/score)

[![buy me a coffee](https://img.buymeacoffee.com/button-api/?text=Buy%20me%20a%20pizza&emoji=🍕&slug=abdullahchauhan&button_colour=FF8838&font_colour=ffffff&font_family=Poppins&outline_colour=000000&coffee_colour=ffffff')](https://www.buymeacoffee.com/abdullahchauhan)

### If you like this package, please leave a like on [pub.dev](https://pub.dev/packages/animated_custom_dropdown) and star on [GitHub](https://github.com/AbdullahChauhan/custom-dropdown).

## Features

Lots of properties to use and customize dropdown widget as per your need. Also usable under Form widget for required validation.

- Custom dropdown using constructor CustomDropdown<T>().
- Custom dropdown with search field using named constructor CustomDropdown<T>.search().
- Custom dropdown with search request field using named constructor CustomDropdown<T>.searchRequest().
- Multi select custom dropdown using named constructor CustomDropdown<T>.multiSelect().
- Multi select custom dropdown with search field using named constructor CustomDropdown<T>.multiSelectSearch().
- Multi select custom dropdown with search request field using named constructor CustomDropdown<T>.multiSelectSearchRequest().

## Preview

<img src="https://raw.githubusercontent.com/AbdullahChauhan/custom-dropdown/master/readme_assets/preview.gif" width="300"/>

<hr>

## Getting started

1. Add the latest version of package to your `pubspec.yaml` (and run `flutter pub get`):

```dart
dependencies:
  animated_custom_dropdown: 3.1.1
```

2. Import the package and use it in your Flutter App.

```dart
import 'package:animated_custom_dropdown/custom_dropdown.dart';
```

<hr>

## Example usage

### **1. Custom dropdown**
```dart
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

const List<String> _list = [
    'Developer',
    'Designer',
    'Consultant',
    'Student',
  ];

class SimpleDropdown extends StatelessWidget {
  const SimpleDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<String>(
      hintText: 'Select job role',
      items: _list,
      initialItem: _list[0],
      onChanged: (value) {
        log('changing value to: $value');
      },
    );
  }
}
```

### **2. Custom dropdown with custom type model**
Let's start with the type of object we are going to work with:
```dart
class Job {
  final String name;
  final IconData icon;
  const Job(this.name, this.icon);

  @override
  String toString() {
    return name;
  }
}
```
Whenever you are going to work with custom type model `T`, your model must override the default `toString()` method and return the property inside that you want to display as list item otherwise the dropdown list item would show `Instance of [model name]`.

Now the widget:

```dart
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

const List<Job> _list = [
    Job('Developer', Icons.developer_mode),
    Job('Designer', Icons.design_services),
    Job('Consultant', Icons.account_balance),
    Job('Student', Icons.school),
  ];

class SimpleDropdown extends StatelessWidget {
  const SimpleDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<Job>(
      hintText: 'Select job role',
      items: _list,
      onChanged: (value) {
        log('changing value to: $value');
      },
    );
  }
}
```
### **3. Custom dropdown with multiple selection**
```dart
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

const List<Job> _list = [
    Job('Developer', Icons.developer_mode),
    Job('Designer', Icons.design_services),
    Job('Consultant', Icons.account_balance),
    Job('Student', Icons.school),
  ];

class MultiSelectDropDown extends StatelessWidget {
  const MultiSelectDropDown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<Job>.multiSelect(
        items: _jobItems,
        initialItems: _jobItems.take(1).toList(),
        onListChanged: (value) {
          log('changing value to: $value');
        },
      );
  }
}
```

### **4. Custom dropdown with search:** *A custom dropdown with the possibility to filter the items.*
First, let's enhance our Job model with more functionality:
```dart
class Job with CustomDropdownListFilter {
  final String name;
  final IconData icon;
  const Job(this.name, this.icon);

  @override
  String toString() {
    return name;
  }

  @override
  bool filter(String query) {
    return name.toLowerCase().contains(query.toLowerCase());
  }
}
```
If the filter on the object is more complex, you can add the `CustomDropdownListFilter` mixin to it, which gives you access to the `filter(query)` method, and by this the items of the list will be filtered.

Now the widgets:

#### SearchDropdown
```dart
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

const List<Job> _list = [
    Job('Developer', Icons.developer_mode),
    Job('Designer', Icons.design_services),
    Job('Consultant', Icons.account_balance),
    Job('Student', Icons.school),
  ];

class SearchDropdown extends StatelessWidget {
  const SearchDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<Job>.search(
      hintText: 'Select job role',
      items: _list,
      excludeSelected: false,
      onChanged: (value) {
        log('changing value to: $value');
      },
    );
  }
}
```

#### MultiSelectSearchDropdown
```dart
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

const List<Job> _list = [
    Job('Developer', Icons.developer_mode),
    Job('Designer', Icons.design_services),
    Job('Consultant', Icons.account_balance),
    Job('Student', Icons.school),
  ];

class MultiSelectSearchDropdown extends StatelessWidget {
  const SearchDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<Job>.multiSelectSearch(
      hintText: 'Select job role',
      items: _list,
      onListChanged: (value) {
        log('changing value to: $value');
      },
    );
  }
}
```

### **5. Custom dropdown with search request:** *A custom dropdown with a search request to load the items.*
Let's use a personalized object for the items:
```dart
class Pair {
  final String text;
  final IconData icon;
  const Pair(this.text, this.icon);

  @override
  String toString() {
    return text;
  }
}
```

Now the widgets:

#### SearchRequestDropdown
```dart
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

const List<Pair> _list = [
    Pair('Developer', Icons.developer_board),
    Pair('Designer', Icons.deblur_sharp),
    Pair('Consultant', Icons.money_off),
    Pair('Student', Icons.edit),
  ];

class SearchRequestDropdown extends StatelessWidget {
  const SearchRequestDropdown({Key? key}) : super(key: key);

  // This should be a call to the api or service or similar
  Future<List<Pair>> _getFakeRequestData(String query) async {
    return await Future.delayed(const Duration(seconds: 1), () {
      return _list.where((e) {
        return e.text.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<Pair>.searchRequest(
      futureRequest: _getFakeRequestData,
      hintText: 'Search job role',
      items: _list,
      onChanged: (value) {
        log('changing value to: $value');
      },
    );
  }
}
```

#### MultiSelectSearchRequestDropdown
```dart
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

const List<Pair> _list = [
    Pair('Developer', Icons.developer_board),
    Pair('Designer', Icons.deblur_sharp),
    Pair('Consultant', Icons.money_off),
    Pair('Student', Icons.edit),
  ];

class MultiSelectSearchRequestDropdown extends StatelessWidget {
  const MultiSelectSearchRequestDropdown({Key? key}) : super(key: key);

  // This should be a call to the api or service or similar
  Future<List<Pair>> _getFakeRequestData(String query) async {
    return await Future.delayed(const Duration(seconds: 1), () {
      return _list.where((e) {
        return e.text.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<Pair>.multiSelectSearchRequest(
      futureRequest: _getFakeRequestData,
      hintText: 'Search job role',
      onListChanged: (value) {
        log('changing value to: $value');
      },
    );
  }
}
```

### **6. Custom dropdown with validation:** *A custom dropdown with validation.*

#### ValidationDropdown
```dart
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

const List<String> _list = [
    'Developer',
    'Designer',
    'Consultant',
    'Student',
  ];

class ValidationDropdown extends StatelessWidget {
  ValidationDropdown({Key? key}) : super(key: key);

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomDropdown<String>(
            hintText: 'Select job role',
            items: _list,
            onChanged: (value) {
              log('changing value to: $value');
            },
            // Run validation on item selected
            validateOnChange: true,
            // Function to validate if the current selected item is valid or not
            validator: (value) => value == null ? "Must not be null" : null,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
              },
              child: const Text(
                'Submit',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

#### MultiSelectValidationDropdown
```dart
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

const List<String> _list = [
    'Developer',
    'Designer',
    'Consultant',
    'Student',
  ];

class MultiSelectValidationDropdown extends StatelessWidget {
  MultiSelectValidationDropdown({Key? key}) : super(key: key);

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomDropdown<String>.multiSelect(
            hintText: 'Select job role',
            items: _list,
            onListChanged: (value) {
              log('changing value to: $value');
            },
            listValidator: (value) => value.isEmpty ? "Must not be null" : null,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
              },
              child: const Text(
                'Submit',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Customization
For a complete customization of the package, go to the [example](https://github.com/AbdullahChauhan/custom-dropdown/blob/master/example).

## Contributors

[![](https://contrib.rocks/image?repo=AbdullahChauhan/custom-dropdown)](https://github.com/AbdullahChauhan/custom-dropdown/graphs/contributors)

## Issues & Feedback

Please file an [issue](https://github.com/AbdullahChauhan/custom-dropdown/issues) to send feedback or report a bug. PRs are always welcome. Thank you!
