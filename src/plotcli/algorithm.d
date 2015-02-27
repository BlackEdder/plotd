/*
	 -------------------------------------------------------------------

	 Copyright (C) 2014, Edwin van Leeuwen

	 This file is part of plotd plotting library.

	 Plotd is free software; you can redistribute it and/or modify
	 it under the terms of the GNU General Public License as published by
	 the Free Software Foundation; either version 3 of the License, or
	 (at your option) any later version.

	 Plotd is distributed in the hope that it will be useful,
	 but WITHOUT ANY WARRANTY; without even the implied warranty of
	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	 GNU General Public License for more details.

	 You should have received a copy of the GNU General Public License
	 along with Plotd. If not, see <http://www.gnu.org/licenses/>.

	 -------------------------------------------------------------------
	 */

module plotcli.algorithm;

import std.range : ElementType, isInputRange, front;

version(unittest)
{
    import std.stdio : writeln;

}
auto groupBy(alias func, R)(R values) if (isInputRange!R)
{
    alias K = typeof(func(values.front));
    alias V = ElementType!R[];
    V[K] grouped;
    foreach (value; values)
        grouped[func(value)] ~= value;
    return grouped;
}

unittest
{
    struct Test
    {
        string a;
        double b;
    }

    auto values = [Test("a", 1), Test("a", 2), Test("b", 3)];
    auto grouped = values.groupBy!((a) => a.a);
    assert(grouped["a"].length == 2);
    assert(grouped["a"][1].b == 2);
    assert(grouped["b"].length == 1);
    assert(grouped["b"][0].b == 3);
}
