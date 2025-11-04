package generators

import stdx.effect.Command
import std.collection.ArrayList

class Yield<Element> <: Command<Unit> {
    Yield(let elem: Element) {}
}

public func yield<T>(element: T) {
    perform Yield<T>(element)
}

public class Generator<Element> {
    public Generator(let f: () -> Unit) {}
    
    public func collect(): ArrayList<Element>() {
        let collection = ArrayList<Element>()
        try {
            f()
        } handle (y: Yield<Element>) {
            collection.add(y.elem)
            resume
        }
        return collection
    }
    
    public func filter(condition: (Element) -> Bool): Generator<Element> {
        return Generator {
            try {
                f()
            } handle (y: Yield<Element>) {
                if (condition(y.elem)) {
                    yield(y.elem)
                }
                resume
            }
        }
    }
    
    public func map<Output>(transform: (Element) -> Output): Generator<Output> {
        return Generator {
            try {
                f()
            } handle (y: Yield<Element>) {
                yield(transform(y.elem))
                resume
            }
        }
    }
    
    public func filter_map<Output>(transform: (Element) -> Option<Output>): Generator<Output> {
        return Generator {
            try {
                 f()
            } handle (y: Yield<Element>) {
                if (let Some(t) <- transform(y.elem)) {
                    yield(t)
                }
                resume
            }
        }
    }

    public func fold<Output>(initial: Output, reducer: (Element, Output) -> Output): Output {
        let accumulator = Box(initial)
        try {
            f()
        } handle (y: Yield<Element>) {
            accumulator.value = reducer(y.elem, accumulator.value)
            resume
        }
        return accumulator.value
    }

    public func take(amount: Int64): Generator<Element> {
        Generator<Element> {
            let amount_left = Box(amount)
            try {
                f()
            } handle (y: Yield<Element>) {
                yield<Element>(y.elem)
                amount_left.value--
                if (amount_left.value > 0) {
                    resume
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
