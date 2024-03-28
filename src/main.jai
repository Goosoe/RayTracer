#import "Basic";
#import "Math";
#import "File";
#import "File_Utilities";
#import "stb_image_write";

IMAGE_X :: 200;
IMAGE_Y :: 100;
FILE_OUTPUT :: "out.jpg";
JPG_CHANNELS :: 3;

// Helper for building the jpg
JPGData :: struct{
    data: [IMAGE_X * IMAGE_Y * JPG_CHANNELS] u8;
    it := 0;
};

main :: ()
{
    jpgData : JPGData;

    y := IMAGE_Y - 1;
    while y >= 0
    {
        defer y -= 1;
        x := 0;
        while x < IMAGE_X
        {
            defer x += 1;
            defer jpgData.it += JPG_CHANNELS;
            r : float = cast(float)x / IMAGE_X;
            g : float = cast(float)y / IMAGE_Y;
            b : float = 0.2;
            ir : u8 = cast(u8)(255.99 * r);
            ig : u8 = cast(u8)(255.99 * g);
            ib : u8 = cast(u8)(255.99 * b);
            jpgData.data[jpgData.it] = ir;
            jpgData.data[jpgData.it + 1] = ig;
            jpgData.data[jpgData.it + 2] = ib;
        }
    }
    stbi_write_jpg(FILE_OUTPUT, IMAGE_X, IMAGE_Y, JPG_CHANNELS, *jpgData.data, 100);
}
