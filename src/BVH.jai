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
        case;
            assert(false, "Shouldn't have gotten here. Some type is wrong");
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

            bb := createSphereBoundingBox(SPHERES[SPHERES_IDX[node.firstObjectIdx]]);

            for 1 .. node.objectCount - 1
            {
                bb = createSurroundingBox(bb, createSphereBoundingBox(SPHERES[node.firstObjectIdx + it])); 
            }
            node.boundingBox = bb;

        case MovingSphere;
            nodeIdx := MOVING_SPHERES_TREE.count - 1;
            node := *MOVING_SPHERES_TREE[nodeIdx];
            if node.objectCount == 0 return;

            bb := createSphereBoundingBox(MOVING_SPHERES[MOVING_SPHERES_IDX[node.firstObjectIdx]]);

            for 1 .. node.objectCount - 1
            {
                bb = createSurroundingBox(bb, createSphereBoundingBox(MOVING_SPHERES[node.firstObjectIdx + it])); 
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
checkBVHCollision :: ($T : Type, ray : Ray, nodeIdx : u64 = 0) -> bool, HitData, T 
{
    #if T ==
    {
        case Sphere;
            node := *SPHERES_TREE[nodeIdx];
            if !checkBoundingBoxCollision(ray, node.boundingBox)
            {
                return false, HitData.{}, Sphere.{};
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
                    return hasHit, hitData, sphereHit;
                }
            }
            else
            {
                hasHitL, hitDataL, sphereHitL := checkBVHCollision(T, ray, node.left);

                hasHitR, hitDataR, sphereHitR := checkBVHCollision(T, ray, node.left + 1);
                if(hitDataL.dist < hitDataR.dist)
                {
                    return hasHitL, hitDataL, sphereHitL;
                }
                else
                {
                    return hasHitR, hitDataR, sphereHitR;
                }
            }

        case MovingSphere;
            node := *MOVING_SPHERES_TREE[nodeIdx];
            if !checkBoundingBoxCollision(ray, node.boundingBox)
            {
                return false, HitData.{}, Sphere.{};
            }

            /* if its a leaf node */
            if node.objectCount != 0
            {
                hasHit := false;
                hitData: HitData;
                sphereHit : Sphere;
                for 0..node.objectCount - 1
                {
                    hit, lastHitData := checkSphereCollision(ray, MOVING_SPHERES[node.firstObjectIdx + it]);
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
                    return hasHit, hitData, sphereHit;
                }
            }
            else
            {
                hasHitL, hitDataL, sphereHitL := checkBVHCollision(T, ray, node.left);

                hasHitR, hitDataR, sphereHitR := checkBVHCollision(T, ray, node.left + 1);
                if(hitDataL.dist < hitDataR.dist)
                {
                    return hasHitL, hitDataL, sphereHitL;
                }
                else
                {
                    return hasHitR, hitDataR, sphereHitR;
                }
            }

        case;
            assert(false, "Shouldn't have gotten here. Some type is wrong");
        }
        return false, HitData.{}, Sphere.{};
}

