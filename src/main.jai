#import "Basic";
#import "File";
#import "File_Utilities";
#import "Math";
#import "Pool";
#import "Random";
#import "System";
#import "Thread";
#import "stb_image_write";

#load "ray.jai";
#load "renderer.jai";
#load "BVH.jai";
#load "perlin.jai";

IMAGE_X :: 1920;
IMAGE_Y :: 1080;
IMAGE_DATA_SIZE :: IMAGE_X * IMAGE_Y * JPG_CHANNELS;
MULTI_THREAD :: true;
NUM_THREADS :: 10;

NUM_WORK : s64 : IMAGE_X * IMAGE_Y;

SCENE_TO_RENDER :: 6;
FILE_OUTPUT :: "out.jpg";


// Helper for building the jpg
JPGData :: struct
{
    data: [IMAGE_DATA_SIZE] u8;
    it := 0;
};

// Struct for the multi threaded renderer
FragmentData :: struct
{
    // Coords of the fragment to sample
    coords : Vector2;
    // Position to write the color obtained
    jpgDataPos : int;
}



// TODO(Goose): create a separate program that runs and generates a file with a static .jai representation of these arrays.
/*scene data*/
SPHERES : [..]  Sphere;
SPHERES_IDX : [..] int;

/* Max size that the tree can have. Of Type Sphere*/
// SPHERES_TREE : [2 ^ BVH_TREE_DEPTH - 1] BVHNode(Sphere);
// 2^BVH_TREE_DEPTH + 1 = 17 
// SPHERES_TREE : [17] BVHNode(Sphere);
// TODO(Goose): WHEN SPHERES IS A FIXED SIZE, USE THAT SIZE HERE. (2 * SPHERES.count) + 1. Imagine that we have 1 object per depth, that will be 2 nodes per object. Thus 2 * objects. +1 because of root node. Also, add a depth limiter, if too many objects.
SPHERES_TREE : [..] BVHNode;

// The moving spheres will only create motion blur if MOTION_BLUR == true. Otherwise they will be erndered the same as static spheres 
MOVING_SPHERES : [..]  MovingSphere;
MOVING_SPHERES_IDX : [..]  int;
MOVING_SPHERES_TREE : [..] BVHNode;

/* MATERIAL DATA */
DIFFUSE_DATA : [..] MaterialDiffuse;

METAL_DATA : [..]  MaterialMetal;

DIELECTRIC_DATA : [..] MaterialDielectric;

/* TEXTURE DATA */
TEXTURE_SOLID : [..] TextureSolid;
TEXTURE_CHECKERED : [..] TextureCheckered;
TEXTURE_PERLIN : [..] TexturePerlin;

threadGroup: Thread_Group;
pool: Pool;

jpgData : *JPGData;

/*
* Initializes data and requests data per pixel of the image. Outputs an image a .jpg in the end
*/


main :: ()
{
    setupCamera();
    #if SCENE_TO_RENDER ==
    {
        case 1;
            setupScene1();
        case 2;
            setupScene2();
        case 3;
            setupScene3();
        case 4;
            setupScene4();
        case 5;
            setupScene5();
        case 6;
            setupScene6();
        case;
            assert(false, "Invalid scene number selected: %\n", SCENE_TO_RENDER);
    }

    createTree(Sphere);

    setupThreadGroup();
#if MULTI_THREAD
{
    start(*threadGroup);
    set_allocators(*pool);  // Init the Pool to use context.allocator.
    allocator: Allocator;
    allocator.proc = pool_allocator_proc;
    allocator.data = *pool;
}

    // not deallocating because it is needed for the whole runtime of the program
    jpgData = cast(*JPGData)alloc(size_of(JPGData));
    // or
    // jpgData := New(JPGData);
    assert(IMAGE_X >= 100, "Image witdth must be > 100");
    assert(IMAGE_Y >= 100, "Image length must be > 100");

    print("Image resolution: %x%\n", IMAGE_X, IMAGE_Y);

    startTime := current_time_consensus();

    for < y: IMAGE_Y - 1..0
    {
        for x: 0..IMAGE_X - 1
        {
#if MULTI_THREAD
{
            defer jpgData.it += JPG_CHANNELS;
            fragmentData := New(FragmentData,, allocator);
            fragmentData.coords = Vector2.{cast(float)x, cast(float)y};
            fragmentData.jpgDataPos = jpgData.it; 
            add_work(*threadGroup, fragmentData, tprint("Work item %", jpgData.it));

}
else
{
            defer jpgData.it += JPG_CHANNELS;
            color := renderFragment(Vector2.{cast(float)x, cast(float)y});

            // Apply the linear to gamma transform.
            color = linearToGamma(color);

            ir : u8 = cast(u8)(255.99 * color.x);
            ig : u8 = cast(u8)(255.99 * color.y);
            ib : u8 = cast(u8)(255.99 * color.z);

            jpgData.data[jpgData.it] = ir;
            jpgData.data[jpgData.it + 1] = ig;
            jpgData.data[jpgData.it + 2] = ib;
}
        }
    }

    workFinished : s64 = 0;
    // When we are done, we shut down the Thread_Group. This is a blocking wait call
    while (workFinished < NUM_WORK)
    {
        sleep_milliseconds(200);
        
        results := get_completed_work(*threadGroup);
        workFinished += results.count;
        print("%\% \n", cast(int)((cast(float)(workFinished) / cast(float)NUM_WORK) * 100));
        reset_temporary_storage();
    }
    endTime := current_time_consensus();
    print("Time elapsed: % seconds\n", to_seconds(endTime - startTime)); 

    shutdown(*threadGroup);
    // writes the fragment data into FILE_OUTPUT
    stbi_write_jpg(FILE_OUTPUT, IMAGE_X, IMAGE_Y, JPG_CHANNELS, *jpgData.data, 100);
    print("Rendering complete, outputted file: %\n", FILE_OUTPUT);
}

setupThreadGroup :: ()
{
    numCpus := get_number_of_processors();
    assert(numCpus >= 1);
    if numCpus > 200  numCpus = 200;  // Clamp to a value that is reasonable as of 2021, in case we get weird data.
    // This is needed if you have an Intel
   // #if (OS == .WINDOWS) || (OS == .LINUX) {
   //     // This routine reports hyperthreads, so, divide by two, because of Intel marketing.
   //     num_cpus /= 2;
   // }

   // to leave a thread available for main
    numThreads := min(numCpus - 1, NUM_THREADS);
    log("This machine reports % CPUs; starting % threads.\n", numCpus, numThreads);

    init(*threadGroup, numThreads, renderFragmentThread);
    threadGroup.name    = "RayCast";
    threadGroup.logging = false;

}

/* Scene setup functions*/

/* Creates a big scene with dozens of static spheres around 3 big spheres. Each of a different material. The floor sphere is checkered */
setupScene1 :: () 
{
    //TODO(Goose): we know how many spheres are in the scene. The arrays can be statically allocated for this scene

    /* Allocate the known textures, such as the dielectric texture */
    array_add(*TEXTURE_SOLID, makeTextureSolid(Vector3.{1,1,1}));

    array_add(*TEXTURE_CHECKERED, makeTextureCheckered(Vector3.{1,1,1}, Vector3.{0.2, 0.5, 0.2}));

    array_add(*DIFFUSE_DATA, makeMaterialDiffuse(Vector3.{1,1,1}, TextureCheckered, TEXTURE_CHECKERED.count -1));

    array_add(*TEXTURE_SOLID, makeTextureSolid(Vector3.{0.6, 0.6, 0.6}));
    array_add(*METAL_DATA, makeMaterialMetal(make_vector3(0.8), TextureSolid, TEXTURE_SOLID.count - 1, 0.001));

    TEXTURE_WHITE_IDX :: 0;

    // Static location of spheres
    array_add(*SPHERES, Sphere.{Vector3.{0, -500, 0}, 500, MaterialType.DIFFUSE, 0});
    array_add(*SPHERES, Sphere.{Vector3.{-2.5, 1, 0.5}, 1, MaterialType.DIFFUSE, 2});
    array_add(*SPHERES, Sphere.{Vector3.{0, 1, 0}, 1, MaterialType.DIELECTRIC, 0});
    array_add(*SPHERES, Sphere.{Vector3.{2.5, 1, -0.5}, 1, MaterialType.METAL, 0});
   
   
    array_add(*DIELECTRIC_DATA, makeMaterialDielectric(Vector3.{1,1,1}, TextureSolid, TEXTURE_WHITE_IDX, 1.5));

    array_add(*DIFFUSE_DATA, MaterialDiffuse.{Vector3.{0.5, 0.5, 0.5}, TextureSolid, TEXTURE_WHITE_IDX});

    // Random location of spheres
    for x: -11..11
    {
        for y: -11..11
        {
            materialChance := random_get_zero_to_one();
            pos := Vector3.{x + 0.9 * random_get_zero_to_one(), 0.15, y + 0.9 * random_get_zero_to_one()};
            tooCloseToBigSpheres := false;

            for 1..3{
                if length(pos - SPHERES[it].center) <= 1.5 * SPHERES[it].radius
                {
                    tooCloseToBigSpheres = true;
                    break;
                }
            }
            // if it's too close, we want to skip adding this sphere
            if length(pos - Vector3.{4, 0.2, 0}) < 0.9 || tooCloseToBigSpheres
            {
                continue;
            }
            // Diffuse
            if materialChance < 0.8
            {
                color := generateRandomVec3();
                array_add(*TEXTURE_SOLID, TextureSolid.{color});
                attenuation := generateRandomVec3();

                array_add(*DIFFUSE_DATA, makeMaterialDiffuse(attenuation, TextureSolid, TEXTURE_SOLID.count - 1));
                array_add(*SPHERES, Sphere.{pos, 0.2, MaterialType.DIFFUSE, DIFFUSE_DATA.count - 1});

            }
            // Metal
            else if materialChance < 0.95
            {
                attenuation := make_vector3(0.5) + (generateRandomVec3() * 0.5);
                fuzz := random_get_zero_to_one() * 0.5;
                array_add(*METAL_DATA, makeMaterialMetal(attenuation, TextureSolid, TEXTURE_WHITE_IDX, fuzz));
                array_add(*SPHERES, Sphere.{pos, 0.2, MaterialType.METAL, METAL_DATA.count - 1});
            }
            // Glass
            else
            {
                array_add(*SPHERES, Sphere.{pos, 0.2, MaterialType.DIELECTRIC, DIELECTRIC_DATA.count - 1});
            }
        }
    }
}

/* Motion blur scene */
setupScene2 :: () 
{
    //TODO(Goose): we know how many spheres are in the scene. The arrays can be statically allocated for this scene
    // Static location of spheres
    array_add(*TEXTURE_SOLID, makeTextureSolid(Vector3.{1,1,1}));

    array_add(*DIFFUSE_DATA, makeMaterialDiffuse(make_vector3(0.5, 0.5, 0.5), TextureSolid, 0));
    array_add(*SPHERES, Sphere.{Vector3.{0, -500, 0}, 500, MaterialType.DIFFUSE, 0});

    attenuation := generateRandomVec3() * generateRandomVec3();
    color := generateRandomVec3() * generateRandomVec3();
    array_add(*DIFFUSE_DATA, makeMaterialDiffuse(attenuation, TextureSolid, 1));
    array_add(*TEXTURE_SOLID, makeTextureSolid(color));

    array_add(*MOVING_SPHERES, MovingSphere.{Sphere.{Vector3.{0.0, 1.5, 0.0}, 1, MaterialType.DIFFUSE, 1}, Vector3.{0.0, 1.0, 0.0}, SHUTTER_TIME - 0.2 });
    array_add(*MOVING_SPHERES, MovingSphere.{Sphere.{Vector3.{0.0, 1.5, 0.0}, 1, MaterialType.DIFFUSE, 1}, Vector3.{0.0, 1.0, 0.0}, SHUTTER_TIME - 0.2 });
    array_add(*MOVING_SPHERES, MovingSphere.{Sphere.{Vector3.{0.0, 1.5, 0.0}, 1, MaterialType.DIFFUSE, 1}, Vector3.{0.0, 1.0, 0.0}, SHUTTER_TIME - 0.2 });
    array_add(*MOVING_SPHERES, MovingSphere.{Sphere.{Vector3.{0.0, 1.5, 0.0}, 1, MaterialType.DIFFUSE, 1}, Vector3.{0.0, 1.0, 0.0}, SHUTTER_TIME - 0.2 });
}

/* Some static spheres scene that render quickly for testing */
setupScene3 :: () 
{
    array_add(*TEXTURE_SOLID, makeTextureSolid(Vector3.{1,1,1}));

    attenuation := generateRandomVec3() * generateRandomVec3();
    color := generateRandomVec3() * generateRandomVec3();
    array_add(*DIFFUSE_DATA, makeMaterialDiffuse(attenuation, TextureSolid, 1));
    array_add(*TEXTURE_SOLID, makeTextureSolid(color));

    // Static location of spheres
    array_add(*DIFFUSE_DATA, makeMaterialDiffuse(Vector3.{0.5, 0.5, 0.5}, TextureSolid, 0));
    array_add(*SPHERES, Sphere.{Vector3.{0, -500, 0}, 500, MaterialType.DIFFUSE, 0});

    color = generateRandomVec3() * generateRandomVec3();
    array_add(*TEXTURE_SOLID, makeTextureSolid(color));
    array_add(*DIFFUSE_DATA, makeMaterialDiffuse(color, TextureSolid, 0));
    array_add(*SPHERES, Sphere.{Vector3.{0.0, 3.5, 0.0}, 1, MaterialType.DIFFUSE, 1});

    array_add(*SPHERES, Sphere.{Vector3.{-2.5, 1, 0.5}, 1, MaterialType.DIFFUSE, 1});
    array_add(*SPHERES, Sphere.{Vector3.{0, 1, 0}, 1, MaterialType.DIFFUSE, 0});
    array_add(*SPHERES, Sphere.{Vector3.{2.5, 1, -0.5}, 1, MaterialType.DIFFUSE, 1});
}

/* Creates a big scene with dozens of static spheres around 3 big spheres. Each of a different material. The floor sphere is a random perlin noise. Similar to scene1 */
setupScene4 :: () 
{
    //TODO(Goose): we know how many spheres are in the scene. The arrays can be statically allocated for this scene

    /* Allocate the known textures, such as the dielectric texture */
    array_add(*TEXTURE_SOLID, makeTextureSolid(Vector3.{1,1,1}));

    array_add(*TEXTURE_PERLIN, makeTexturePerlin(Vector3.{0.5,0.5,0.5}, 7.0));
    array_add(*DIFFUSE_DATA, makeMaterialDiffuse(Vector3.{1,1,1}, TexturePerlin, TEXTURE_PERLIN.count -1));

    array_add(*TEXTURE_SOLID, makeTextureSolid(Vector3.{0.6, 0.6, 0.6}));
    array_add(*METAL_DATA, makeMaterialMetal(make_vector3(0.8), TextureSolid, TEXTURE_SOLID.count - 1, 0.001));

    TEXTURE_WHITE_IDX :: 0;

    // Static location of spheres
    array_add(*SPHERES, Sphere.{Vector3.{0, -500, 0}, 500, MaterialType.DIFFUSE, 0});
    array_add(*SPHERES, Sphere.{Vector3.{-2.5, 1, 0.5}, 1, MaterialType.DIFFUSE, 2});
    array_add(*SPHERES, Sphere.{Vector3.{0, 1, 0}, 1, MaterialType.DIELECTRIC, 0});
    array_add(*SPHERES, Sphere.{Vector3.{2.5, 1, -0.5}, 1, MaterialType.METAL, 0});
   
   
    array_add(*DIELECTRIC_DATA, makeMaterialDielectric(Vector3.{1,1,1}, TextureSolid, TEXTURE_WHITE_IDX, 1.5));

    array_add(*DIFFUSE_DATA, MaterialDiffuse.{Vector3.{0.5, 0.5, 0.5}, TextureSolid, TEXTURE_WHITE_IDX});

    // Random location of spheres
    for x: -11..11
    {
        for y: -11..11
        {
            materialChance := random_get_zero_to_one();
            pos := Vector3.{x + 0.9 * random_get_zero_to_one(), 0.15, y + 0.9 * random_get_zero_to_one()};
            tooCloseToBigSpheres := false;

            for 1..3{
                if length(pos - SPHERES[it].center) <= 1.5 * SPHERES[it].radius
                {
                    tooCloseToBigSpheres = true;
                    break;
                }
            }
            // if it's too close, we want to skip adding this sphere
            if length(pos - Vector3.{4, 0.2, 0}) < 0.9 || tooCloseToBigSpheres
            {
                continue;
            }
            // Diffuse
            if materialChance < 0.8
            {
                color := generateRandomVec3();
                array_add(*TEXTURE_SOLID, TextureSolid.{color});
                attenuation := generateRandomVec3();

                array_add(*DIFFUSE_DATA, makeMaterialDiffuse(attenuation, TextureSolid, TEXTURE_SOLID.count - 1));
                array_add(*SPHERES, Sphere.{pos, 0.2, MaterialType.DIFFUSE, DIFFUSE_DATA.count - 1});

            }
            // Metal
            else if materialChance < 0.95
            {
                attenuation := make_vector3(0.5) + (generateRandomVec3() * 0.5);
                fuzz := random_get_zero_to_one() * 0.5;
                array_add(*METAL_DATA, makeMaterialMetal(attenuation, TextureSolid, TEXTURE_WHITE_IDX, fuzz));
                array_add(*SPHERES, Sphere.{pos, 0.2, MaterialType.METAL, METAL_DATA.count - 1});
            }
            // Glass
            else
            {
                array_add(*SPHERES, Sphere.{pos, 0.2, MaterialType.DIELECTRIC, DIELECTRIC_DATA.count - 1});
            }
        }
    }
}

/* Some static spheres scene that render quickly with the Perlin texture that gives a marble like texture */
setupScene5 :: () 
{
    // ADD TEXTURES
    array_add(*TEXTURE_SOLID, makeTextureSolid(Vector3.{1,1,1}));

    attenuation := generateRandomVec3() * generateRandomVec3();
    color := generateRandomVec3() * generateRandomVec3();
    array_add(*TEXTURE_SOLID, makeTextureSolid(color));
    array_add(*TEXTURE_PERLIN, makeTexturePerlin(Vector3.{0.5,0.5,0.5}, 7.0));

    // ADD MATERIALS
    array_add(*DIFFUSE_DATA, makeMaterialDiffuse(attenuation, TextureSolid, 1));
    array_add(*DIFFUSE_DATA, makeMaterialDiffuse(Vector3.{1,1,1}, TexturePerlin, TEXTURE_PERLIN.count - 1));

    array_add(*SPHERES, Sphere.{Vector3.{0, 2, 0}, 2, MaterialType.DIFFUSE, 1});
    array_add(*SPHERES, Sphere.{Vector3.{0, -500, 0}, 500, MaterialType.DIFFUSE, 0});
}
/* Some static spheres scene that render quickly for testing */
setupScene6 :: () 
{
    // ADD TEXTURES
    array_add(*TEXTURE_SOLID, makeTextureSolid(Vector3.{1,1,1}));

    attenuation := generateRandomVec3() * generateRandomVec3();
    color := generateRandomVec3() * generateRandomVec3();
    array_add(*TEXTURE_SOLID, makeTextureSolid(color));

    // ADD MATERIALS
    array_add(*DIFFUSE_DATA, makeMaterialDiffuse(attenuation, TextureSolid, 0));
    array_add(*DIFFUSE_DATA, makeMaterialDiffuse(Vector3.{1,1,1}, TextureSolid, 1));

    array_add(*SPHERES, Sphere.{Vector3.{0, 2, 0}, 2, MaterialType.DIFFUSE, 1});
    array_add(*SPHERES, Sphere.{Vector3.{0, -500, 0}, 500, MaterialType.DIFFUSE, 0});
}
