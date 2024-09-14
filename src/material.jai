/**
*   Texture application and functions for objects   
*/

#import "Basic";
#import "Math";

//TODO(Goose): This can be replaced by compile time Type verification. This is a solution "A la C"

/* Material definition */

MaterialType :: enum u8
{
    DIFFUSE :: 0;
    METAL;
    DIELECTRIC; //Materials like water and glass
    EMISSIVE;
}


MaterialData :: struct
{
    material : MaterialType;
    materialId : int; // id in material array
}

MaterialDiffuse :: struct
{
    attenuation : Vector3;
    textureType : Type;
    textureIdx : int;
}

MaterialMetal :: struct
{
    using material : MaterialDiffuse;
    fuzz : float;
}

MaterialDielectric :: struct
{
    using material : MaterialDiffuse;
    indexOfRefraction : float;
}

MaterialEmissive :: struct
{
    using material : MaterialDiffuse;
    emissiveValue : Vector3;
}

/* *** */
/* Texture definition */

// TEXTURE_SOLID : [..] ConstantTexture;

// Textures :: enum u8
// {
//     SOLID :: 0;
// }

/* The classic single colored texture. */
TextureSolid :: struct
{
    color : Vector3;
}

TextureCheckered :: struct
{
    using texture : TextureSolid;
    color2 : Vector3;
}

TexturePerlin :: struct
{
    using texture : TextureSolid;
    scale : float;
    perlin : PerlinNoise;
}

/** MATERIALS **/
makeMaterialData :: (material : MaterialType, materialId : int) -> MaterialData
{
    return MaterialData.{material, materialId};
}

makeMaterialDiffuse :: (attenuation : Vector3, textureType : Type, textureIdx : int ) -> MaterialDiffuse
{
    return MaterialDiffuse.{attenuation, textureType, textureIdx};
}

makeMaterialDielectric :: (attenuation : Vector3, textureType : Type, textureIdx : int, fuzz : float) -> MaterialDielectric
{
    return .{MaterialDiffuse.{attenuation, textureType, textureIdx}, fuzz};
}

makeMaterialMetal :: (attenuation : Vector3, textureType : Type, textureIdx : int, indexOfRefraction : float) -> MaterialMetal
{
    return .{MaterialDiffuse.{attenuation, textureType, textureIdx}, indexOfRefraction};
}

makeMaterialEmissive :: (attenuation : Vector3, emissiveValue : Vector3, textureType : Type, textureIdx : int) -> MaterialEmissive
{
    return MaterialEmissive.{makeMaterialDiffuse(attenuation, textureType, textureIdx), emissiveValue};
}

/** TEXTURES **/
makeTextureSolid :: (color : Vector3) -> TextureSolid
{
    return .{color};
}

makeTextureCheckered :: (color1 : Vector3, color2 : Vector3) -> TextureCheckered
{
    return .{TextureSolid.{color1}, color2};
}

makeTexturePerlin :: (color : Vector3, scale : float) -> TexturePerlin
{
    return .{TextureSolid.{color}, scale, makePerlinNoise()};
}

/* Gets a texture color  */
getTextureAtUV :: (textureType : Type, uv : Vector2, position : Vector3, idx : int) -> Vector3
{
    /* TODO(Goose): this switch is done at runtime. Make it at compile-time */
    if textureType ==
    {
        case TextureSolid;
            return TEXTURE_SOLID[idx].color;

        case TextureCheckered;
            return calculateTextureCheckered(uv, position, idx);

        case TexturePerlin;
        tex := TEXTURE_PERLIN[idx];
             return tex.color * (1 + sin(tex.scale * position.z + 10 * getPerlinTurbulence(*tex, position, 7)));

        case;
            assert(false, "Texture of type: % is not implemented", textureType);
    }
    return Vector3.{0, 0, 0};
}

calculateTextureCheckered :: (uv : Vector2, position : Vector3, idx : int) -> Vector3
{
    texData := TEXTURE_CHECKERED[idx];
    sinVal := sin(10 * position.x) * sin(10 * position.y) * sin(10 * position.z);
    
    if sinVal < 0.0
    {
        return texData.color;
    }
    else
    {
        return texData.color2;
    }
}
