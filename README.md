# Generator-like objects with limited iterator features using effects and non-deferred resumptions

This is an experiment using effect handlers in Cangjie to create a similar experience to generator syntax in Python/JavaScript/C++23.

By not relying on deferred resumptions, we can have certain lazy operations like map, filter, take etc... and some operations consuming the whole "iterator" like fold. However anything that would consume the "iterator" partially and keep its state to consume the rest of the elements later would require deferred resumption. In particular, this object here does not implement `std.core.Iterator<...>`.

## Fibonacci example

The benefit of this kind of thing is to express certain iterators in a possibly more intuitive way:
```cangjie
import iterator.*

func fibonacci() {
    Generator<Int64> {
        var current: Int64
        var last: Int64
        yield(last)
        yield(current)

        while (true) {
            (last, current) = (current, last+current)
            yield(current)
        }
    }
}
```

## Drawbacks

Some experiments find that using these alternative "iterators" can be about one order of magnitude slower than implementing `std.core.Iterator<...>`, however this appears to be a similar performance hit as using `std::generator` in C++23 with GCC with g++ 15.