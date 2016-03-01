module plotcli.geom;

import ggplotd.geom;
 
private string generateToGeom()
{
    import std.traits;
    import std.string : toLower;
    string str;
    foreach( name; __traits(allMembers, ggplotd.geom) )
    {
        //auto name = m.stringof;
        static if (name.length > 6 && name[0..4] == "geom"
            && name != "geomRectangle" 
            && name != "geomEllipse" 
            && name != "geomDiamond" 
            && name != "geomTriangle"
            && name != "geomAxis" )
        {
            str ~= "if (type == q{" ~ name[4..$].toLower ~ "})\n";
            str ~= "\treturn " ~ name ~ "!R(g).array;\n";
            str ~= "else ";
        }
    }

    str ~= "\nreturn geomPoint!R(g).array;\n";

    return str;
}

auto toGeom( R )( R g, string type )
{
    import std.array : array;
    //pragma( msg, generateToGeom );
    mixin(generateToGeom);
}

