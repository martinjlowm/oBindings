declare class oBindingsClass {
  RegisterKeyBindings(this: oBindingsClass, name: string, ...bindings: any[]): void;
}

declare const oBindings: oBindingsClass;

/** @forRange */
declare function forRange(start: number, limit: number, step?: number): number[];

/** @vararg */
interface Vararg<T> extends Array<T> {}
