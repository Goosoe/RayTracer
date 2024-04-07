#import "Basic";
#import "Math";
#import "File";
#import "File_Utilities";
#import "Random";
#import "stb_image_write";

#load "objects.jai";
#load "renderer.jai";

IMAGE_X :: 800;
IMAGE_Y :: 400;
FILE_OUTPUT :: "out.jpg";

// Helper for building the jpg
JPGData :: struct
{
    data: [IMAGE_X * IMAGE_Y * JPG_CHANNELS] u8;
    it := 0;
};

/*scene data*/
SPHERES := Sphere.[
    Sphere.{Vector3.{0, -100.5, -1}, 100, Materials.DIFFUSE, 1},    // Big sphere to work as ground
    Sphere.{Vector3.{1.5, 0, -1}, 0.5, Materials.DIELECTRIC, 0},
    Sphere.{Vector3.{-1.5, 0, -1}, 0.5, Materials.METAL, 0},
    // Sphere.{Vector3.{0, 0, -1}, 0.5, Materials.DIFFUSE, 0},
    Sphere.{Vector3.{0, 0, -1}, 0.5, Materials.DIFFUSE, 1},
];

DIFFUSE_DATA := DiffuseData.[
    DiffuseData.{Vector3.{0.5, 0.5, 0.5}},
    DiffuseData.{Vector3.{0.8, 0.8, 0.0}},
    DiffuseData.{Vector3.{0.2, 0.7, 0.2}},
];

METAL_DATA := MetalData.[
    MetalData.{Vector3.{0.2, 0.2, 0.2}, 0},  //pure reflective metal
    MetalData.{Vector3.{0.2, 0.2, 0.2}, 0.5},  //fuzzy metal
];

DIELECTRIC_DATA := DielectricData.[
    DielectricData.{Vector3.{1,1,1}, 1.5},
    DielectricData.{Vector3.{0.5,0.5,0.5}, 1.0},
];
/**/

/*
* Initializes data and requests data per pixel of the image. Outputs an image a .jpg in the end
*/
main :: ()
{
    // not deallocating because it is needed for the whole runtime of the program
    jpgData : *JPGData = cast(*JPGData)alloc(size_of(JPGData));
    // or
    // jpgData := New(JPGData);
    assert(IMAGE_X >= 100, "Image witdth must be > 100");
    assert(IMAGE_Y >= 100, "Image length must be > 100");
    assert(ZOOM > 0, "Zoom must be > 0");

    for < y: IMAGE_Y - 1..0
    {
        for x: 0..IMAGE_X - 1
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
    // writes the fragment data into FILE_OUTPUT
    stbi_write_jpg(FILE_OUTPUT, IMAGE_X, IMAGE_Y, JPG_CHANNELS, *jpgData.data, 100);
}
