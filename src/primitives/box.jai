/*Not really a primitive, but it's useful to have a box object*/
#import "Basic";

BOX_NUM_OF_QUADS :: 6;
Box :: struct
{
    quads : [6] AuxQuad;
    center : Vector3;
    translate : Vector3;
    //TODO(Goose): If I want to implement rotations in all axis, change this to Vector3
    rotationY : float;
}

makeBox :: (p1 : Vector3, p2 : Vector3, materialData : MaterialData, translate : Vector3 = Vector3.{0,0,0}, rotationY : float = 0.0) -> Box
{
    box : Box;
    box.quads[0] = makeAuxQuad(p1.x, p2.x, p1.y, p2.y, p2.z, PlaneAligned.XY, materialData);
    box.quads[1] = makeAuxQuad(p1.x, p2.x, p1.y, p2.y, p1.z, PlaneAligned.XY, materialData);

    box.quads[2] = makeAuxQuad(p1.x, p2.x, p1.z, p2.z, p2.y, PlaneAligned.XZ, materialData);
    box.quads[3] = makeAuxQuad(p1.x, p2.x, p1.z, p2.z, p1.y, PlaneAligned.XZ, materialData);

    box.quads[4] = makeAuxQuad(p1.y, p2.y, p1.z, p2.z, p2.x, PlaneAligned.YZ, materialData);
    box.quads[5] = makeAuxQuad(p1.y, p2.y, p1.z, p2.z, p1.x, PlaneAligned.YZ, materialData);
    box.center = (p1 + p2) * 0.5;
    box.translate = translate;
    box.rotationY = rotationY;
    return box;
}

checkBoxCollision :: (ray : Ray, box : Box) -> bool, HitData, MaterialData
{
    hit : bool;
    hitData : HitData;
    materialData : MaterialData;
    translatedRay := Ray.{ray.origin - box.translate, ray.direction, ray.shutterTime};
    for 0 .. BOX_NUM_OF_QUADS - 1
    {
        lastHit, lastHitData := checkAuxQuadCollision(translatedRay, box.translate, box.quads[it]);
        if !lastHit
        {
            continue;
        }
        if hitData.dist > lastHitData.dist
        {
            hit = lastHit;
            hitData = lastHitData;
            materialData = box.quads[it].materialData;
        }
    }
    return hit, hitData, materialData;
}
