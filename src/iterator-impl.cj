package generators
import std.core.Iterable
import effects

class Start <: effects.Command<Unit> {
    Start() {}
}


extend<Element> Generator<Element> <: Iterable<Element> {
    public func iterator(): StopStart<Element> {
        iterator(start_provided : false)
    }

    /* Alternative where you can perform Start before generating any elements for some
     * computations to be performed at creation before consuming the iterator elements
     */
    public func iterator(start_provided!: Bool): StopStart<Element> {
        let output: Box<?StopStart<Element>> = Box(None)

        // Discard the output of this because we know it will (/should) be None
        // from the Start handler
        effects.try_deferrable<?(Element, StopStart<Element>)> {
            if (!start_provided) {
                effects.perform(Start())
            }
            this.f()
            None // Signals end of generator
        } .handle { y: Yield<Element>, r: effects.Resumption<Unit, ?(Element, StopStart<Element>)> =>
            Some((y.elem, StopStart<Element>(r)))
        } .handle { _: Start, r: effects.Resumption<Unit, ?(Element, StopStart<Element>)> =>
            output.value = StopStart(r)
            Option<(Element, StopStart<Element>)>.None // Discarded (output of this try-handle block)
        } .then_finally {}

        return output.value.getOrThrow()
    }
}

class StopStart<Element> <: Iterator<Element> {
    StopStart(var value: effects.Resumption<Unit, ?(Element, StopStart<Element>)>) {}

    public func next(): ?Element {
        match (effects.resume(this.value, ())) {
            case Some((elem, r)) =>
                this.value = r.value
                elem
            case _ => None
        }
    }
}