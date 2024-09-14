#import "Basic";

/**
* point - position of one of the edges of the quad
* u, v - vectors that define the two sides of the quad
* normal - normal unit vector of the quad
* d - dot product (magnitude) between normal and point
*/
Quad :: struct
{
    point : Vector3;
    u : Vector3;
    v : Vector3;
    normal : Vector3;
    d : float64;
    material : MaterialType;
    materialId : int; // id in material array
}

createQuad :: (point : Vector3, u : Vector3, v : Vector3, material : MaterialType, materialId : int) -> Quad
{
    normal : Vector3 = unit_vector(cross_product(u, v));
    quad : Quad = Quad.{
        point,
        u,
        v,
        normal,
        dot_product(normal, point),
        material,
        materialId
    };
    return quad;
}

checkQuadCollision :: (ray : Ray, quad : Quad) -> bool, HitData
{  
    //TODO(Goose): Implement collision math
    return false, HitData.{};
}
