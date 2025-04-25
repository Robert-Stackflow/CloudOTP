<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->
[![pub package](https://img.shields.io/pub/v/smart_snackbars.svg)](https://pub.dev/packages/smart_snackbars)

# Creativity of using this package is endless.

#### This package facilitates you to create very highly customized SnackBars on the go with any animation curve.
#### More creative examples are on the way.

## Features

![](https://github.com/ToyZ-95/smart_snackbars/blob/master/example/assets/smart_snackbars_gif.gif)

## Getting started

Just add dependency of smart_snackbars and boom you can create amazing SnackBars using your creativity.

## Usage

### A snackbar with pre-defined ui

```dart
SmartSnackBars.showTemplatedSnackbar(
      context: context,
      backgroundColor: Colors.green,
      animateFrom: AnimateFrom.fromTop,
      leading: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        child: const Icon(
          Icons.check,
          color: Colors.white,
        ),
      ),
      titleWidget: const Text(
        "Good Job",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      subTitleWidget: const Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          "Data is submitted",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      trailing: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: const Icon(
          Icons.close,
          color: Colors.white,
        ),
      ),
    );
```

### A persisting SnackBar with dismissible capabilities

```dart
SmartSnackBars.showCustomSnackBar(
      context: context,
      persist: true,
      duration: const Duration(milliseconds: 1000),
      animationCurve: Curves.bounceOut,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Row(
          children: [
            const SizedBox(
              width: 5,
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.2),
              ),
              child: const Icon(
                Icons.info_outline,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Data is deleted",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.close,
              color: Colors.white,
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
```

### A snackbar showing a network call and loading indicator

```dart
SmartSnackBars.showCustomSnackBar(
      context: context,
      duration: const Duration(milliseconds: 1000),
      animateFrom: AnimateFrom.fromBottom,
      distanceToTravel: 0.0,
      outerPadding: const EdgeInsets.all(0),
      child: Column(
        children: [
          SizedBox(
            height: 5,
            child: LinearProgressIndicator(
              backgroundColor: Colors.black.withValues(alpha: 0.7),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            color: Colors.black.withValues(alpha: 0.7),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Text(
                  "Sending Data To Server...",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.blue,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    "Stop",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 20)
              ],
            ),
          ),
        ],
      ),
    );
```





## Additional information

We will be more than happy of your contributions. 
<br />
Please contribute to [smart_snackbars](https://github.com/ToyZ-95/smart_snackbars) this github repo
