#import "Basic";

/**
* Plane bound quads.
* p1** - plane 1 values
* p2** - plane 2 values
* k - position along the plane that is static (e.g - the X plane in a quad in YZ plane 
*/
Quad :: struct
{
    p1x0 : float;
    p1x1 : float;
    p2x0 : float;
    p2x1 : float;
    k : float;
    center : Vector3;
    //TODO(Goose): if we want to add translation and rotation to the quad uncomment
    // translate : Vector3;
    // rotate : Vector3;
    alignement: PlaneAligned;
    materialData : MaterialData;
}
// Used for other primitives such as box
AuxQuad :: struct
{
    p1x0 : float;
    p1x1 : float;
    p2x0 : float;
    p2x1 : float;
    k : float;
    center : Vector3;
    alignement: PlaneAligned;
    materialData : MaterialData;
}

PlaneAligned :: enum
{
    XY;
    XZ;
    YZ;
}

makeQuad :: (p1x0 : float, p1x1 : float, p2x0 : float, p2x1 : float, k : float, alignement : PlaneAligned, materialData : MaterialData /* translate : Vector3 = Vector3.{0,0,0} */) -> Quad
{
    center : Vector3;
    if alignement ==
    {
        case PlaneAligned.XY;
            center = Vector3.{0.5 * (p1x0 + p1x1), 0.5 * (p2x0 + p2x1), k};
        case PlaneAligned.XZ;
            center = Vector3.{0.5 * (p1x0 + p1x1), k, 0.5 * (p2x0 + p2x1)};
        case PlaneAligned.YZ;
            center = Vector3.{k, 0.5 * (p1x0 + p1x1), 0.5 * (p2x0 + p2x1)};
    }
    quad : Quad = Quad.{
        p1x0,
        p1x1,
        p2x0,
        p2x1,
        k,
        center,
        // translate,
        alignement,
        materialData
    };
    return quad;
}

makeAuxQuad :: (p1x0 : float, p1x1 : float, p2x0 : float, p2x1 : float, k : float, alignement : PlaneAligned, materialData : MaterialData) -> AuxQuad
{
    center : Vector3;
    if alignement ==
    {
        case PlaneAligned.XY;
            center = Vector3.{0.5 * (p1x0 + p1x1), 0.5 * (p2x0 + p2x1), k};
        case PlaneAligned.XZ;
            center = Vector3.{0.5 * (p1x0 + p1x1), k, 0.5 * (p2x0 + p2x1)};
        case PlaneAligned.YZ;
            center = Vector3.{k, 0.5 * (p1x0 + p1x1), 0.5 * (p2x0 + p2x1)};
    }
    quad : AuxQuad = AuxQuad.{
        p1x0,
        p1x1,
        p2x0,
        p2x1,
        k,
        center,
        alignement,
        materialData
    };
    return quad;
}

checkQuadCollision :: (ray : Ray, quad : Quad) -> bool, HitData
{
    hitResult := false;
    hitData := HitData.{};
    t : float;
    p1Val : float;
    p2Val : float;
    normal : Vector3;
    if quad.alignement ==
    {
        case PlaneAligned.XY;
            t = (quad.k - ray.origin.z) / ray.direction.z;
            if t < MIN_DIST || t > MAX_DIST 
            {
                return hitResult, hitData;
            }
            p1Val = ray.origin.x + (t * ray.direction.x);
            p2Val = ray.origin.y + (t * ray.direction.y);
            normal = Vector3.{0,0,1};
        case PlaneAligned.XZ;
            t = (quad.k - ray.origin.y) / ray.direction.y;
            if t < MIN_DIST || t > MAX_DIST 
            {
                return hitResult, hitData;
            }
            p1Val = ray.origin.x + (t * ray.direction.x);
            p2Val = ray.origin.z + (t * ray.direction.z);
            normal = Vector3.{0,1,0};
        case PlaneAligned.YZ;
            t = (quad.k - ray.origin.x) / ray.direction.x;
            if t < MIN_DIST || t > MAX_DIST 
            {
                return hitResult, hitData;
            }
            p1Val = ray.origin.y + (t * ray.direction.y);
            p2Val = ray.origin.z + (t * ray.direction.z);
            normal = Vector3.{1,0,0};
    }

    if p1Val < quad.p1x0 || p1Val > quad.p1x1 || p2Val < quad.p2x0 || p2Val > quad.p2x1
    {
        return hitResult, hitData;
    }

    hitData.uv = Vector2.{(p1Val - quad.p1x0) / (quad.p1x1 - quad.p1x0),
                            (p2Val - quad.p2x0) / (quad.p2x1 - quad.p2x0)};
    hitData.dist = t;
    frontFace := dot_product(ray.direction, normal) < 0;
    if !frontFace then normal = -normal;
    hitData.normal = normal;
    hitData.frontFace = frontFace;
    hitData.coordinates = pointAt(ray, t);
    hitResult = true;
    return hitResult, hitData;
}

checkAuxQuadCollision :: (ray : Ray, box : Box, quadIt : int) -> bool, HitData
{
    hitResult := false;
    hitData := HitData.{};
    t : float;
    p1Val : float;
    p2Val : float;
    normal : Vector3;
    quad := box.quads[quadIt];

    transformedRay := ray;
    // translate 
    transformedRay.origin.x -= box.translate.x; //+ quad.center.x;
    transformedRay.origin.y -= box.translate.y; //+ (quad.center.y / 2);
    transformedRay.origin.z -= box.translate.z; //+ quad.center.z;

    //TODO(Goose): in the future, if we want to add more rotation types, we must apply them accordingly
    // apply the Y rotate
    transformedRay.origin.x = (box.cosTetha * transformedRay.origin.x) + (box.sinTetha * transformedRay.origin.z);
    transformedRay.direction.x = (box.cosTetha * transformedRay.direction.x) + (box.sinTetha * transformedRay.direction.z);

    transformedRay.origin.z = (-box.sinTetha * transformedRay.origin.x) + (box.cosTetha * transformedRay.origin.z);
    transformedRay.direction.z = (-box.sinTetha * transformedRay.direction.x) + (box.cosTetha * transformedRay.direction.z);


    if quad.alignement ==
    {
        case PlaneAligned.XY;

            t = (quad.k - transformedRay.origin.z) / transformedRay.direction.z;
            if t < MIN_DIST || t > MAX_DIST 
            {
                return hitResult, hitData;
            }
            p1Val = transformedRay.origin.x + (t * transformedRay.direction.x);
            p2Val = transformedRay.origin.y + (t * transformedRay.direction.y);

            normal = Vector3.{0,0,1};
            normal.y = (box.cosTetha * normal.x) - (box.sinTetha * normal.z);
            normal.x = (box.cosTetha * normal.x) - (box.sinTetha * normal.z);

        case PlaneAligned.XZ;

            t = (quad.k - transformedRay.origin.y) / transformedRay.direction.y;
            if t < MIN_DIST || t > MAX_DIST 
            {
                return hitResult, hitData;
            }
            p1Val = transformedRay.origin.x + (t * transformedRay.direction.x);
            p2Val = transformedRay.origin.z + (t * transformedRay.direction.z);

            normal = Vector3.{0,1,0};
            normal.x = (box.cosTetha * normal.x) - (box.sinTetha * normal.z);
            normal.z = (box.sinTetha * normal.x) + (box.cosTetha * normal.z);

        case PlaneAligned.YZ;
            t = (quad.k - transformedRay.origin.x) / transformedRay.direction.x;
            if t < MIN_DIST || t > MAX_DIST 
            {
                return hitResult, hitData;
            }
            p1Val = transformedRay.origin.y + (t * transformedRay.direction.y);
            p2Val = transformedRay.origin.z + (t * transformedRay.direction.z);

            normal = Vector3.{1,0,0};
            normal.y = (box.cosTetha * normal.x) - (box.sinTetha * normal.z);
            normal.z = (box.sinTetha * normal.x) + (box.cosTetha * normal.z);
    }

    if p1Val < quad.p1x0 || p1Val > quad.p1x1 || p2Val < quad.p2x0 || p2Val > quad.p2x1
    {
        return hitResult, hitData;
    }


    hitData.uv = Vector2.{(p1Val - quad.p1x0) / (quad.p1x1 - quad.p1x0),
                            (p2Val - quad.p2x0) / (quad.p2x1 - quad.p2x0)};
    hitData.dist = t;
    frontFace := dot_product(transformedRay.direction, normal) < 0;
    if !frontFace then normal = -normal;
    hitData.normal = normal;
    hitData.frontFace = frontFace;
    //usually affects the reflection of the faces
    hitData.coordinates = pointAt(transformedRay, t) + box.translate;
    hitResult = true;
    return hitResult, hitData;
}
