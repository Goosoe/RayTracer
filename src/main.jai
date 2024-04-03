#import "Basic";
#import "Math";
#import "File";
#import "File_Utilities";
#import "Random";
#import "stb_image_write";

#load "objects.jai";
#load "renderer.jai";

IMAGE_X :: 800;
IMAGE_Y :: 600;
FILE_OUTPUT :: "out.jpg";

// Helper for building the jpg
JPGData :: struct
{
    data: [IMAGE_X * IMAGE_Y * JPG_CHANNELS] u8;
    it := 0;
};

/*scene data*/
SPHERES := Sphere.[
    Sphere.{Vector3.{0, -100.5, -1}, 100},    // Big sphere to work as ground
    Sphere.{Vector3.{0, 0, -1}, 0.5},
    Sphere.{Vector3.{1, 1, -3}, 0.5},
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

            coords := make_vector2(cast(float)x, cast(float)y);
            #if ANTI_ALIASING
            {
                //TODO(Goose): the random should affect the UV, not the coords
                color : Vector3;
                for 0.. AA_SAMPLE_NUM
                {
                    random:= Vector2.{-0.5 + random_get_zero_to_one(), -0.5 + random_get_zero_to_one()};
                    color += renderFragment(coords + random);
                }
                Clamp(*(color.x / AA_SAMPLE_NUM), 0, 1);
                Clamp(*(color.y / AA_SAMPLE_NUM), 0, 1);
                Clamp(*(color.z / AA_SAMPLE_NUM), 0, 1);
            }
            else
            {
                color := renderFragment(coords);
            }
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
