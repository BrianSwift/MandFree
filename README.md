# MandFree: Mandelbrot explorer for tvOS and iOS

MandFree is a FLOSS version of Mandelbits (v1), an AppleTV app which was available in the App Store on the new Apple TV from December 2015 to October 2016.

This is a basic double precision Mandelbrot using NEON SIMD operations to simultaneously calculate pairs of pixel values.

Smooth zooming and level of detail management is leveraged from CATiledLayer.

However, zooming is restricted to 20 levels due to UIScrollView precision limitations.
