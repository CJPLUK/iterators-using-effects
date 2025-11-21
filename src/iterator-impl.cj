package generators
import std.core.Iterable
import effects

class Start <: effects.Command<Unit> {
    Start() {}
}


extend<Element> Generator<Element> <: Iterable<Element> { //where Element <: Default {
    public func iterator(): StopStart<Element> {
        let output = effects.try_deferrable<Option<(Element, StopStart<Element>)>> {
            // effects.perform(Start())
            this.f()
            Option<(Element, StopStart<Element>)>.None
        } .handle { y: Yield<Element>, r: effects.Resumption<Unit, Option<(Element, StopStart<Element>)>> =>
            Some((y.elem, StopStart<Element>(r)))
        // } .handle { s: Start, r: effects.Resumption<Unit, Option<(Element, StopStart<Element>)>> =>
        //     Some((Element.default(), StopStart<Element>(r)))
        } .then_finally {}
        return output.getOrThrow()[1]
    }

}

class StopStart<Element> <: Iterator<Element> {
    StopStart(var value: effects.Resumption<Unit, Option<(Element, StopStart<Element>)>>) {}
    public func next(): Option<Element> {
        match (effects.resume(this.value, ())) {
            case Some((elem, r)) =>
                this.value = r.value // (any alternative to make ownership move transparent?)
                elem
            case _ => None
        }
    }
}