/** @luaIterator @tupleReturn */
interface LuaIterator extends Iterable<string> {}
declare function pairs(tbl: any): LuaIterator;
declare function ipairs(tbl: any): LuaIterator;
