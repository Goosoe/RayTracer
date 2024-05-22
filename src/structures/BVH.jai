#import "Basic";
#import "Math";

//TODO(Goose): problems to fix:
// Right now we have the original SPHERES list being reorganized. This will make us get the wrong data when trying to traverse to the leaves and get the data. Need to think of a way to fix it.
//https://jacco.ompf2.com/2022/04/13/how-to-build-a-bvh-part-1-basics/
// Make a test to see if it is working properly
//TODO(Goose): this could be a parameter if not being used anywhere else
// nodesUsed := 0;

BVHNode :: struct//($T : Type)
{
    /**/
    // Allocate memory for all the nodes and use the index to access it 
    left : u64;
    //right index is left + 1
    // right : u64;

    // the node has a bounding box to see if it is hit or not by the ray
    using boundingBox : BoundingBox;

    firstObjectIdx : u64;
    /* If its a leaf node, we will have objectCount > 0*/
    objectCount : u64;
    // TODO(Goose): A dynamic array in a struct is a bad idea. Maybe add another level of indirection so it's faster to iterate over?
    // objectIndices : [..] u64;
    /* We want to have the type to know which table to search for the data*/
    // type : T;

}

/* Creates a BVH tree with the given input */
// createTree :: ($T : Type, totalDepth : u64, currentDepth : u64 = 0, currentIndex : u64 = 0) //-> bool //*BVHNode()
createTree :: ($T : Type)
{

    // Note: 2*totalDepth - 1 is the max number of nodes we will need to allocate
    // go over objects and get the boundingbox limits

    // TODO(Goose): allocate memory for the tree
    // TODO(Goose): USE T Type switch case

    /* Initialize the root node */
    // node := *SPHERE_TREE[0];
    node := array_add(*SPHERE_TREE);
    // node := *SPHERE_TREE[0];
    node.objectCount = cast(u64) SPHERES.count;
    for 0..SPHERES.count - 1
    {
        array_add(*SPHERES_IDX, it);
        // array_add(*node.objectIndices, cast(u64) it);
    }
    //root node will use nodesUsed == 0
    // nodesUsed += 1;
    print("NODE 0: %\n", <<node);



    // subdivide(T, totalDepth, currentDepth + 1, currentIndex + 1);
    updateNodeBounds(T);

    // DEBUG - can remove this after testing
    if node.objectCount == 1
    {
        print("Tree created with a total number of nodes: %\n",SPHERE_TREE.count);
        for 0..SPHERE_TREE.count - 1
        {
            print("Node %: %\n", it, SPHERE_TREE[it]);
        }
        return;
    }

    subdivide(T);

    // print("Tree created with a total number of nodes: %\n", nodesUsed);
    // for 0..SPHERE_TREE.count - 1
    // {
    //     print("Node %: %\n", it, SPHERE_TREE[it]);
    // }
}
updateNodeBounds :: ($T : Type, currentDepth : u64 = 0)
{
    // if currentDepth == BVH_TREE_DEPTH 
    // {
    //     // print("------- REACHED MAX DEPTH % WITH NODE %. NOT UPDATING BOUNDS------\n", currentDepth, nodeIdx);
    //     return;
    // }
    print("-------STARTED UPDATING BOUNDS------\n");

    #if T ==
    {
   
        case Sphere;
            // bb := createBoundingBox();
            nodeIdx := SPHERE_TREE.count - 1;
            node := *SPHERE_TREE[nodeIdx];
            if node.objectCount == 0 return;
            // if node.objectCount == 0 return;
            // node.firstObjectIdx = 0;
            // node.objectCount = 1;
            // bb := createSphereBoundingBox(SPHERES[node.firstObjectIdx]);
            bb := createSphereBoundingBox(SPHERES[SPHERES_IDX[node.firstObjectIdx]]);

            // for 1..node.objectCount - 1
            print("Node % is working with the indices: % %\n", nodeIdx, node.firstObjectIdx, node.objectCount);
            for 1..node.objectCount - 1
            {
                // node.firstObjectIdx + it;
                // node.objectCount += 1;
                bb = createSurroundingBox(bb, createSphereBoundingBox(SPHERES[node.firstObjectIdx + it])); 
            }
            node.boundingBox = bb;
            print("CurrentBoundingBox: %\n", bb);
            print("-------FINISHED UPDATING BOUNDS------\n");
            // print("node: %\n", <<node);
            // print("node in tree: %\n", SPHERE_TREE[nodeIdx]);

        case MovingSphere;
            for MOVING_SPHERES
            {

            }
        case;
            assert(false, "Shouldn't have gotten here. Some type is wrong");
    }

}

/* Recursive call from createTree*/
// subdivide :: (primitiveType : $T, totalDepth : u64, currentDepth: u64, currentIndex : u64) //-> bool //*BVHNode()
subdivide :: ($T : Type, currentDepth : u64 = 0) //-> bool //*BVHNode():
{
    // assert(currentIndex > 0, "currentIndex must be > 0. Initialize the root node in createTree function, as this function expects for the root node to already be initialized.");
    // assert(currentDepth > 0, "currentDepth must be > 0. Initialize the root node in createTree function, as this function expects for the root node to already be initialized.");
    // if totalDepth == currentDepth return;


    // if currentDepth == BVH_TREE_DEPTH 
    // {
    //     // print("------- REACHED MAX DEPTH % WITH NODE %. NOT SUBDIVIDING------\n", currentDepth, nodeIdx);
    //     return;
    // }
    // print("-------STARTING SUBDIVISION OF NODE %. CURRENT DEPTH %------\n", nodeIdx, currentDepth);
    // print("Current Depth with node: %\n", currentDepth, nodeIdx);
    #if T ==
    {
        case Sphere;
            print("Is left node: % %\n", SPHERE_TREE.count % 2 == 0, SPHERE_TREE.count % 2);

            // node := SPHERE_TREE[SPHERE_TREE.count - 1 + (SPHERE_TREE.count % 2)];
            node := SPHERE_TREE[SPHERE_TREE.count - 1];
            // node := array_add(*SPHERE_TREE);
            //TODO(Goose): After debugging, we can remove this variable 
            nodeIdx := SPHERE_TREE.count - 1;
            /* if we have only one object, there is no need to keep separating */
            // if node.objectCount < 2
            if node.objectCount < 2
            {
                print("Node %  has % object. No need to go deeper on this!\n", nodeIdx, node.objectCount);
                print("NodeData % \n", node);
                return;
            }

            // print("parent node in tree: % %\n", node, SPHERE_TREE.count - 1 + (SPHERE_TREE.count % 2));

            /* Subdivide the plane */
            print("huh % %\n", node.max, node.min);
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

            print("splitPos % in axis %\n", splitPos, axis);
            /* Split the plane in two by organizing the primitive list*/
            /* Use these indexes for organizing the object list in left and right of spliPos*/
            // leftIdx := node.firstObjectIdx;
            // rightIdx := node.firstObjectIdx + node.objectCount - 1;
            leftIdx : u64 = node.firstObjectIdx;
            rightIdx : u64 = cast(u64) node.objectCount - 1;

            print("Before sort: %\n", SPHERES);
            print("leftIdx, rightIdx, firstObjectIdx, objectCount: %, %, %, %\n", leftIdx, rightIdx, node.firstObjectIdx, node.objectCount );
            while leftIdx <= rightIdx
            {
                if getAxis(axis, SPHERES[leftIdx].center) < splitPos
                {
                    leftIdx += 1;
                }
                else
                {
                    //TODO(Goose): we are changing the SPHERES list. When it will be set as a static table, we should use a copy of it instead for these calculations
                    Swap(*SPHERES_IDX[leftIdx], *SPHERES_IDX[rightIdx]);
                    rightIdx -= 1;
                    print("Sphere list was sorted in idx: %\n", nodeIdx);
                }
            }
            print("After sort: %\n", SPHERES_IDX);
            print("leftIdx, rightIdx, firstObjectIdx, objectCount: %, %, %, %\n", leftIdx, rightIdx, node.firstObjectIdx, node.objectCount );
            //TODO(Goose): Empty nodes on separation not being handled properly...
            /*  Create child nodes */
            // leftCount := leftIdx - node.firstObjectIdx;
            // if leftCount == 0 || leftCount == node.objectCount return;

            leftCount := leftIdx - node.firstObjectIdx;
            // abort split if one of the sides is empty
            // if leftCount == 0 || leftCount == node.objectCount || currentDepth == BVH_TREE_DEPTH return;
            if leftCount == 0 || leftCount == node.objectCount return;

            // nodesUsed += 1;
            nodeL := array_add(*SPHERE_TREE);
            leftChildIdx := cast(u64) SPHERE_TREE.count - 1;
            print("leftchildidx: %\n",leftChildIdx);
            // nodesUsed += 1;
            nodeL.firstObjectIdx = node.firstObjectIdx;
            nodeL.objectCount = leftCount;


            // rightChildIdx := cast(u64) nodesUsed;
            nodeR := array_add(*SPHERE_TREE);
            nodeR.firstObjectIdx = leftIdx;
            nodeR.objectCount = node.objectCount - leftCount;
            print("rightchildidx: %\n",leftChildIdx + 1);
            node.left = cast(u64) leftChildIdx;
           // for node.objectCount
           // {
           //     if getAxis(axis, SPHERES[it].center) < splitPos
           //     {
           //         array_add(*SPHERE_TREE[leftChildIdx].objectIndices, it);
           //     }
           //     else
           //     {
           //         array_add(*SPHERE_TREE[rightChildIdx].objectIndices, it);
           //     }
           // }
            print("Clearing parent node array % %\n", node.firstObjectIdx, node.objectCount);
            node.objectCount = 0;
            // array_reset(*node.objectIndices);
            print("Added indices to left node: % %\n", node.firstObjectIdx, node.objectCount);
            print("Added indices to right node: % %\n", node.firstObjectIdx, node.objectCount);
            print("-------FINISHED SUBDIVISION OF NODE % WITH DEPTH %------\n", nodeIdx, currentDepth);
            // SPHERE_TREE[leftChildIdx].firstObjectIdx = node.firstObjectIdx;
            // SPHERE_TREE[leftChildIdx].objectCount = leftCount;
            // SPHERE_TREE[leftChildIdx].Type = T;

            // SPHERE_TREE[rightChildIdx].firstObjectIdx = leftIdx;
            // SPHERE_TREE[rightChildIdx].objectCount = node.objectCount - leftCount;
            // SPHERE_TREE[leftChildIdx].Type = T;
            // node.objectCount = 0;


            // print("Total Depth: %\n", totalDepth);
            // print("currentDepth: %\n", currentDepth);

            // if node.objectCount < 2  || currentDepth == BVH_TREE_DEPTH 
            // {
            //     print("reached the max depth or object count == 1.\n %\n", <<node);
            //     return;
            // }

            //TODO(Goose): Add more primitive types now

        case MovingSphere;
            for MOVING_SPHERES
            {
            }
        case;
    }


    updateNodeBounds(T, currentDepth + 1);
    updateNodeBounds(T, currentDepth + 1);

    subdivide(T, currentDepth + 1);
    subdivide(T, currentDepth + 1);
    // print("%\n", type_of(objects[0]));
    // print("%\n", << objects);
    // subdivide(primitiveType, totalDepth, currentDepth + 1, currentIndex + 1);
    //subdivide(T, 0);
}

/* Checks for a collision of the given ray with the objects defined in the BVHTree data */
checkBVHCollision :: ($T : Type, ray : Ray, nodeIdx : u64 = 0) -> bool, HitData, T 
{
    #if T ==
    {
        case Sphere;
            node := *SPHERE_TREE[nodeIdx];
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

                //TODO(Goose): Optimize this
                hasHitR, hitDataR, sphereHitR := checkBVHCollision(T, ray, node.left + 1);
                // if hasHitL && !hasHitR
                // {
                //     return hasHitL, hitDataL, sphereHitL;
                // }
                // else if !hasHitL && hasHitR
                // {
                //     return hasHitR, hitDataR, sphereHitR;
                // }
                // else if hasHitL && hasHitR
                // {
                    if(hitDataL.dist < hitDataR.dist)
                    {
                        return hasHitL, hitDataL, sphereHitL;
                    }
                    else
                    {
                        return hasHitR, hitDataR, sphereHitR;
                    }
                // }
            }

        case MovingSphere;

        case;
            assert(false, "Shouldn't have gotten here. Some type is wrong");
        }
        return false, HitData.{}, Sphere.{};
}

