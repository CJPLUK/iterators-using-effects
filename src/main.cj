package generators

import std.collection.ArrayList
import effects

interface Default {
    static func default() : Default
}

class Yield<Element> <: effects.Command<Unit> {
    Yield(let elem: Element) {}
    public func defaultImpl() {
        eprintln("non-handled yield")
    }
}

public func yield<T>(element: T) {
    effects.perform(Yield<T>(element))
}

public class Generator<Element> {
    public Generator(let f: () -> Unit) {}
    
    public func collect(): ArrayList<Element> {
        let collection = ArrayList<Element>()
        effects.try_ {
            f()
        } .handle { y: Yield<Element> =>
            collection.add(y.elem)
        }.then_finally {}
        return collection
    }
    
    public func filter(condition: (Element) -> Bool): Generator<Element> {
        return Generator {
            effects.try_ {
                f()
            } .handle { y: Yield<Element> =>
                if (condition(y.elem)) {
                    yield(y.elem)
                }
            }.then_finally {}
        }
    }
    
    public func map<Output>(transform: (Element) -> Output): Generator<Output> {
        return Generator {
            effects.try_ {
                f()
            } .handle { y: Yield<Element> =>
                yield(transform(y.elem))
            }.then_finally {}
        }
    }
    
    public func filter_map<Output>(transform: (Element) -> Option<Output>): Generator<Output> {
        return Generator {
            effects.try_ {
                 f()
            } .handle { y: Yield<Element> =>
                if (let Some(t) <- transform(y.elem)) {
                    yield(t)
                }
            } .then_finally {}
        }
    }

    public func fold<Output>(initial: Output, reducer: (Element, Output) -> Output): Output {
        let accumulator = Box(initial)
        effects.try_ {
            f()
        } .handle { y: Yield<Element> =>
            accumulator.value = reducer(y.elem, accumulator.value)
            return
        } .then_finally {}
        return accumulator.value
    }

    public func take(amount: Int64): Generator<Element> {
        Generator<Element> {
            let amount_left = Box(amount)
            effects.try_ {
                f()
            } .handle { y: Yield<Element> =>
                yield<Element>(y.elem)
                amount_left.value--
                if (amount_left.value > 0) {
                    return
                }
            }
        }
    }
}

public func range(start: Int64, end: Int64): Generator<Int64> {
    return Generator<Int64> {
        for (x in start..end) {
            yield(x)
        }
    }
}

main() {
    println("hello")

    println(range(1, 8000).iterator().max())
    return
}
