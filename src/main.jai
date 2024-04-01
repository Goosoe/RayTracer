#import "Basic";
#import "Math";
#import "File";
#import "File_Utilities";
#import "stb_image_write";

#load "objects.jai";
#load "renderer.jai";

IMAGE_X :: 800;
IMAGE_Y :: 600;
FILE_OUTPUT :: "out.jpg";
JPG_CHANNELS :: 3;

// Helper for building the jpg
JPGData :: struct
{
    data: [IMAGE_X * IMAGE_Y * JPG_CHANNELS] u8;
    it := 0;
};


/*
* Initializes data and requests data per pixel of the image. Outputs an image a .jpg in the end
*/
main :: ()
{
    jpgData : JPGData;
    assert(IMAGE_X >= 100);
    assert(IMAGE_Y >= 100);
    ratio := calculateImageRatio();
    lowerLeftCornerCoord := make_vector3(-ratio.x, -ratio.y, -1.0);
    horizontal := make_vector3(ratio.x * 2, 0.0, 0.0);
    vertical := make_vector3(0.0, ratio.y * 2, 0.0);
    camera : Camera;

    // iterates over every fragment
    y := IMAGE_Y - 1;
    while y >= 0
    {
        defer y -= 1;
        x := 0;
        while x < IMAGE_X
        {
            defer x += 1;
            defer jpgData.it += JPG_CHANNELS;

            uv := make_vector2(cast(float) x / IMAGE_X, cast(float) y / IMAGE_Y);
            ray := Ray.{camera.location, lowerLeftCornerCoord + (uv.x * horizontal) + (uv.y * vertical)};

            // Creates the background color. Varies between white and blue
            //todo: implement mee
            // #if ANTI_ALIASING
                color := renderFragmentAliasing(ray);
            // #else !ANTI_ALIASING
                // color := renderFragment(ray);
            // #endif

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
