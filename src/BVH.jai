#import "Basic";
#import "Math";

BVHNode :: struct//($T : Type)
{
    left : u64;
    //right index is left + 1

    // the node has a bounding box to see if it is hit or not by the ray
    using boundingBox : BoundingBox;

    firstObjectIdx : u64;
    /* If its a leaf node, we will have objectCount > 0*/
    objectCount : u64;
}

/* Creates a BVH tree with the given input */
createTree :: ($T : Type)
{
    // Note: 2*totalDepth - 1 is the max number of nodes we will need to allocate
    // go over objects and get the boundingbox limits

    #if T ==
    {
   
        case Sphere;
            /* Initialize the root node */
            node := array_add(*SPHERES_TREE);
            node.objectCount = cast(u64) SPHERES.count;
            for 0 .. SPHERES.count - 1
            {
                array_add(*SPHERES_IDX, it);
            }

        case MovingSphere;
            /* Initialize the root node */
            node := array_add(*MOVING_SPHERES_TREE);
            node.objectCount = cast(u64) MOVING_SPHERES.count;
            for 0 .. MOVING_SPHERES.count - 1
            {
                array_add(*MOVING_SPHERES_IDX, it);
            }
        case Quad;
            node := array_add(*QUADS_TREE);
            node.objectCount = cast(u64) QUADS.count;
            for 0 .. QUADS.count - 1
            {
                array_add(*QUADS_IDX, it);
            }
        case Box;
            node := array_add(*BOXES_TREE);
            node.objectCount = cast(u64) BOXES.count;
            for 0 .. BOXES.count - 1
            {
                array_add(*BOXES_IDX, it);
            }
        case;
            assert(false, "CREATE BVH TREE: Shouldn't have gotten here. Some type is wrong");
        }

    updateNodeBounds(T);
    if node.objectCount == 1 return;

    subdivide(T);
}

updateNodeBounds :: ($T : Type, currentDepth : u64 = 0)
{
    #if T ==
    {

        case Sphere;
            nodeIdx := SPHERES_TREE.count - 1;
            node := *SPHERES_TREE[nodeIdx];
            if node.objectCount == 0 return;

            bb := createBoundingBox(SPHERES[SPHERES_IDX[node.firstObjectIdx]]);

            for 1 .. node.objectCount - 1
            {
                bb = createSurroundingBox(*bb, *createBoundingBox(SPHERES[node.firstObjectIdx + it])); 
            }
            node.boundingBox = bb;

        case MovingSphere;
            nodeIdx := MOVING_SPHERES_TREE.count - 1;
            node := *MOVING_SPHERES_TREE[nodeIdx];
            if node.objectCount == 0 return;

            bb := createBoundingBox(MOVING_SPHERES[MOVING_SPHERES_IDX[node.firstObjectIdx]]);

            for 1 .. node.objectCount - 1
            {
                bb = createSurroundingBox(*bb, *createBoundingBox(MOVING_SPHERES[node.firstObjectIdx + it])); 
            }
            node.boundingBox = bb;

        case Quad;
            nodeIdx := QUADS_TREE.count - 1;
            node := *QUADS_TREE[nodeIdx];
            if node.objectCount == 0 return;

            bb := createBoundingBox(QUADS[QUADS_IDX[node.firstObjectIdx]]);

            for 1 .. node.objectCount - 1
            {
                bb = createSurroundingBox(*bb, *createBoundingBox(QUADS[node.firstObjectIdx + it])); 
            }
            node.boundingBox = bb;
        case Box;
            nodeIdx := BOXES_TREE.count - 1;
            node := *BOXES_TREE[nodeIdx];
            if node.objectCount == 0 return;

            bb := createBoundingBox(BOXES[BOXES_IDX[node.firstObjectIdx]]);

            for 1 .. node.objectCount - 1
            {
                bb = createSurroundingBox(*bb, *createBoundingBox(BOXES[node.firstObjectIdx + it])); 
            }
            node.boundingBox = bb;

        case;
            assert(false, "Shouldn't have gotten here. Some type is wrong");
        }
}

/* Recursive call from createTree*/
subdivide :: ($T : Type, currentDepth : u64 = 0) //-> bool //*BVHNode():
{
    #if T ==
    {
        case Sphere;
            node := SPHERES_TREE[SPHERES_TREE.count - 1];

            if node.objectCount < 2 return;
            

            /* Subdivide the plane */
            extent := node.max - node.min;
            axis := 0;
            if extent.y > extent.x
            {
                axis = 1;
            }
            if extent.z > getAxis(axis, extent)
            {
                axis = 2;
            }
            splitPos := getAxis(axis, node.min) + getAxis(axis, extent) * 0.5;

            /* Split the plane in two by organizing the primitive list*/
            /* Use these indexes for organizing the object list in left and right of spliPos*/
            leftIdx : u64 = node.firstObjectIdx;
            rightIdx : u64 = cast(u64) node.objectCount - 1;
            while leftIdx < rightIdx
            {
                if getAxis(axis, SPHERES[leftIdx].center) < splitPos
                {
                    leftIdx += 1;
                }
                else
                {
                    Swap(*SPHERES_IDX[leftIdx], *SPHERES_IDX[rightIdx]);
                    rightIdx -= 1;
                }
            }

            leftCount := leftIdx - node.firstObjectIdx;
            /* Abort split if one of the sides is empty */
            if leftCount == 0 || leftCount == node.objectCount return;

            nodeL := array_add(*SPHERES_TREE);
            leftChildIdx := cast(u64) SPHERES_TREE.count - 1;
            nodeL.firstObjectIdx = node.firstObjectIdx;
            nodeL.objectCount = leftCount;


            nodeR := array_add(*SPHERES_TREE);
            nodeR.firstObjectIdx = leftIdx;
            nodeR.objectCount = node.objectCount - leftCount;

            node.left = cast(u64) leftChildIdx;
            node.objectCount = 0;

        case MovingSphere;
            node := MOVING_SPHERES_TREE[MOVING_SPHERES_TREE.count - 1];
            /* if we have only one object, there is no need to keep separating */
            if node.objectCount < 2 return;

            /* Subdivide the plane */
            extent := node.max - node.min;
            axis := 0;
            if extent.y > extent.x
            {
                axis = 1;
            }
            if extent.z > getAxis(axis, extent)
            {
                axis = 2;
            }
            splitPos := getAxis(axis, node.min) + getAxis(axis, extent) * 0.5;

            /* Split the plane in two by organizing the primitive list*/
            /* Use these indexes for organizing the object list in left and right of spliPos*/
            leftIdx : u64 = node.firstObjectIdx;
            rightIdx : u64 = cast(u64) node.objectCount - 1;

            while leftIdx < rightIdx
            {
                if getAxis(axis, MOVING_SPHERES[leftIdx].center) < splitPos
                {
                    leftIdx += 1;
                }
                else
                {
                    Swap(*MOVING_SPHERES_IDX[leftIdx], *MOVING_SPHERES_IDX[rightIdx]);
                    rightIdx -= 1;
                }
            }

            /*  Create child nodes */
            leftCount := leftIdx - node.firstObjectIdx;
            /* Abort split if one of the sides is empty */
            if leftCount == 0 || leftCount == node.objectCount return;

            nodeL := array_add(*MOVING_SPHERES_TREE);
            leftChildIdx := cast(u64) MOVING_SPHERES_TREE.count - 1;
            nodeL.firstObjectIdx = node.firstObjectIdx;
            nodeL.objectCount = leftCount;

            nodeR := array_add(*MOVING_SPHERES_TREE);
            nodeR.firstObjectIdx = leftIdx;
            nodeR.objectCount = node.objectCount - leftCount;

            node.left = cast(u64) leftChildIdx;
            node.objectCount = 0;

        case Quad;
            node := QUADS_TREE[QUADS_TREE.count - 1];
            /* if we have only one object, there is no need to keep separating */
            if node.objectCount < 2 return;

            /* Subdivide the plane */
            extent := node.max - node.min;
            axis := 0;
            if extent.y > extent.x
            {
                axis = 1;
            }
            if extent.z > getAxis(axis, extent)
            {
                axis = 2;
            }
            splitPos := getAxis(axis, node.min) + getAxis(axis, extent) * 0.5;

            /* Split the plane in two by organizing the primitive list*/
            /* Use these indexes for organizing the object list in left and right of spliPos*/
            leftIdx : u64 = node.firstObjectIdx;
            rightIdx : u64 = cast(u64) node.objectCount - 1;

            while leftIdx < rightIdx
            {
                if getAxis(axis, QUADS[leftIdx].center) < splitPos
                {
                    leftIdx += 1;
                }
                else
                {
                    Swap(*QUADS_IDX[leftIdx], *QUADS_IDX[rightIdx]);
                    rightIdx -= 1;
                }
            }

            /*  Create child nodes */
            leftCount := leftIdx - node.firstObjectIdx;
            /* Abort split if one of the sides is empty */
            if leftCount == 0 || leftCount == node.objectCount return;

            nodeL := array_add(*QUADS_TREE);
            leftChildIdx := cast(u64) QUADS_TREE.count - 1;
            nodeL.firstObjectIdx = node.firstObjectIdx;
            nodeL.objectCount = leftCount;

            nodeR := array_add(*QUADS_TREE);
            nodeR.firstObjectIdx = leftIdx;
            nodeR.objectCount = node.objectCount - leftCount;

            node.left = cast(u64) leftChildIdx;
            node.objectCount = 0;
        case Box;
            node := BOXES_TREE[BOXES_TREE.count - 1];
            /* if we have only one object, there is no need to keep separating */
            if node.objectCount < 2 return;

            /* Subdivide the plane */
            extent := node.max - node.min;
            axis := 0;
            if extent.y > extent.x
            {
                axis = 1;
            }
            if extent.z > getAxis(axis, extent)
            {
                axis = 2;
            }
            splitPos := getAxis(axis, node.min) + getAxis(axis, extent) * 0.5;

            /* Split the plane in two by organizing the primitive list*/
            /* Use these indexes for organizing the object list in left and right of spliPos*/
            leftIdx : u64 = node.firstObjectIdx;
            rightIdx : u64 = cast(u64) node.objectCount - 1;

            while leftIdx < rightIdx
            {
                if getAxis(axis, BOXES[leftIdx].center) < splitPos
                {
                    leftIdx += 1;
                }
                else
                {
                    Swap(*BOXES_IDX[leftIdx], *BOXES_IDX[rightIdx]);
                    rightIdx -= 1;
                }
            }

            /*  Create child nodes */
            leftCount := leftIdx - node.firstObjectIdx;
            /* Abort split if one of the sides is empty */
            if leftCount == 0 || leftCount == node.objectCount return;

            nodeL := array_add(*BOXES_TREE);
            leftChildIdx := cast(u64) BOXES_TREE.count - 1;
            nodeL.firstObjectIdx = node.firstObjectIdx;
            nodeL.objectCount = leftCount;

            nodeR := array_add(*BOXES_TREE);
            nodeR.firstObjectIdx = leftIdx;
            nodeR.objectCount = node.objectCount - leftCount;

            node.left = cast(u64) leftChildIdx;
            node.objectCount = 0;
        case;
            assert(false, "Shouldn't have gotten here. Some type is wrong");
    }


    updateNodeBounds(T, currentDepth + 1);
    updateNodeBounds(T, currentDepth + 1);

    if leftIdx == rightIdx return;

    subdivide(T, currentDepth + 1);
    subdivide(T, currentDepth + 1);
}

/* Checks for a collision of the given ray with the objects defined in the BVHTree data */
checkBVHCollision :: ($T : Type, ray : Ray, nodeIdx : u64 = 0) -> bool, HitData, MaterialData
{
    #if T ==
    {
        case Sphere;
            if SPHERES_TREE.count == 0
            {
                return false, HitData.{}, MaterialData.{};
            }

            node := *SPHERES_TREE[nodeIdx];
            if !checkBoundingBoxCollision(ray, node.boundingBox)
            {
                return false, HitData.{}, MaterialData.{};
            }

            /* if its a leaf node */
            if node.objectCount != 0
            {
                hasHit := false;
                hitData: HitData;
                sphereHit : Sphere;
                for 0..node.objectCount - 1
                {
                    hit, lastHitData := checkSphereCollision(ray, SPHERES[node.firstObjectIdx + it]);
                    if hit && lastHitData.dist < hitData.dist
                    {
                        hasHit = true;
                        hitData = lastHitData;
                        sphereHit = SPHERES[node.firstObjectIdx + it];
                        // print("Got a hit! Node Indice: %. Sphere: %\n", it, SPHERES[it]);
                    }
                }
                if hasHit
                {
                    // print("% %\n", hitData, sphereHit);
                    return hasHit, hitData, sphereHit.materialData;
                }
            }
            else
            {
                hasHitL, hitDataL, materialDataL := checkBVHCollision(T, ray, node.left);

                hasHitR, hitDataR, materialDataR := checkBVHCollision(T, ray, node.left + 1);
                if(hitDataL.dist < hitDataR.dist)
                {
                    return hasHitL, hitDataL, materialDataL;
                }
                else
                {
                    return hasHitR, hitDataR, materialDataR;
                }
            }

        case MovingSphere;
            if MOVING_SPHERES_TREE.count == 0
            {
                return false, HitData.{}, MaterialData.{};
            }

            node := *MOVING_SPHERES_TREE[nodeIdx];
            if !checkBoundingBoxCollision(ray, node.boundingBox)
            {
                return false, HitData.{}, MaterialData.{};
            }

            /* if its a leaf node */
            if node.objectCount != 0
            {
                hasHit := false;
                hitData: HitData;
                sphereHit : MovingSphere;
                for 0..node.objectCount - 1
                {
                    hit, lastHitData := checkMovingSphereCollision(ray, MOVING_SPHERES[node.firstObjectIdx + it]);
                    if hit && lastHitData.dist < hitData.dist
                    {
                        hasHit = true;
                        hitData = lastHitData;
                        sphereHit = MOVING_SPHERES[node.firstObjectIdx + it];
                        // print("Got a hit! Node Indice: %. Sphere: %\n", it, SPHERES[it]);
                    }
                }
                if hasHit
                {
                    // print("% %\n", hitData, sphereHit);
                    return hasHit, hitData, sphereHit.sphere.materialData;
                }
            }
            else
            {
                hasHitL, hitDataL, materialDataL := checkBVHCollision(T, ray, node.left);

                hasHitR, hitDataR, materialDataR := checkBVHCollision(T, ray, node.left + 1);
                if(hitDataL.dist < hitDataR.dist)
                {
                    return hasHitL, hitDataL, materialDataL;
                }
                else
                {
                    return hasHitR, hitDataR, materialDataR;
                }
            }

        case Quad;
            if QUADS_TREE.count == 0
            {
                return false, HitData.{}, MaterialData.{};
            }


            node := *QUADS_TREE[nodeIdx];
            if !checkBoundingBoxCollision(ray, node.boundingBox)
            {
                return false, HitData.{}, MaterialData.{};
            }

            /* if its a leaf node */
            if node.objectCount != 0
            {
                hasHit := false;
                hitData: HitData;
                quadHit : Quad;
                for 0..node.objectCount - 1
                {
                    hit, lastHitData := checkQuadCollision(ray, QUADS[node.firstObjectIdx + it]);
                    if hit && lastHitData.dist < hitData.dist
                    {
                        hasHit = true;
                        hitData = lastHitData;
                        quadHit = QUADS[node.firstObjectIdx + it];
                    }
                }
                if hasHit
                {
                    return hasHit, hitData, quadHit.materialData;
                }
            }
            else
            {
                hasHitL, hitDataL, materialDataL := checkBVHCollision(T, ray, node.left);

                hasHitR, hitDataR, materialDataR := checkBVHCollision(T, ray, node.left + 1);
                if(hitDataL.dist < hitDataR.dist)
                {
                    return hasHitL, hitDataL, materialDataL;
                }
                else
                {
                    return hasHitR, hitDataR, materialDataR;
                }
            }
        case Box;
            if BOXES_TREE.count == 0
            {
                return false, HitData.{}, MaterialData.{};
            }

            
            node := *BOXES_TREE[nodeIdx];
            if !checkBoundingBoxCollision(ray, node.boundingBox)
            {
                return false, HitData.{}, MaterialData.{};
            }

            /* if its a leaf node */
            if node.objectCount != 0
            {
                hasHit := false;
                hitData: HitData;
                boxHit : Box;
                materialData : MaterialData;
                for 0..node.objectCount - 1
                {
                    box := BOXES[node.firstObjectIdx + it];
                    hit, lastHitData, materialData:= checkBoxCollision(ray,  box);
                    if hit && lastHitData.dist < hitData.dist
                    {
                        hasHit = true;
                        hitData = lastHitData;
                        boxHit = box;
                    }
                }
                if hasHit
                {
                    return hasHit, hitData, boxHit.quads[0].materialData;
                }
            }
            else
            {
                hasHitL, hitDataL, materialDataL := checkBVHCollision(T, ray, node.left);

                hasHitR, hitDataR, materialDataR := checkBVHCollision(T, ray, node.left + 1);
                if(hitDataL.dist < hitDataR.dist)
                {
                    return hasHitL, hitDataL, materialDataL;
                }
                else
                {
                    return hasHitR, hitDataR, materialDataR;
                }
            }
        case;
            assert(false, "Shouldn't have gotten here. Some type is wrong");
        }
        return false, HitData.{}, MaterialData.{};
}

