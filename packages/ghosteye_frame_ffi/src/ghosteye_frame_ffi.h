#include <stdint.h>

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

typedef struct GhosteyeRgbImage {
  uint8_t* data;
  int32_t length;
  int32_t width;
  int32_t height;
} GhosteyeRgbImage;

FFI_PLUGIN_EXPORT int32_t ghosteye_bgra8888_to_rgb(
    const uint8_t* bgra,
    int32_t width,
    int32_t height,
    int32_t bytes_per_row,
    int32_t max_dimension,
    GhosteyeRgbImage* out_image);

FFI_PLUGIN_EXPORT int32_t ghosteye_yuv420_to_rgb(
    const uint8_t* y_plane,
    int32_t y_bytes_per_row,
    const uint8_t* u_plane,
    int32_t u_bytes_per_row,
    int32_t u_bytes_per_pixel,
    const uint8_t* v_plane,
    int32_t v_bytes_per_row,
    int32_t v_bytes_per_pixel,
    int32_t width,
    int32_t height,
    int32_t max_dimension,
    GhosteyeRgbImage* out_image);

FFI_PLUGIN_EXPORT void ghosteye_frame_free_buffer(uint8_t* buffer);

FFI_PLUGIN_EXPORT int32_t ghosteye_frame_active_allocations(void);

/* Combined conversion + JPEG encoding — returns a malloc-owned JPEG buffer.
   Call ghosteye_jpeg_free_buffer() to release it. */

typedef struct GhosteyeJpegImage {
  uint8_t* data;
  int32_t  length;
} GhosteyeJpegImage;

FFI_PLUGIN_EXPORT int32_t ghosteye_bgra8888_to_jpeg(
    const uint8_t* bgra,
    int32_t width,
    int32_t height,
    int32_t bytes_per_row,
    int32_t max_dimension,
    int32_t quality,
    GhosteyeJpegImage* out_image);

FFI_PLUGIN_EXPORT int32_t ghosteye_yuv420_to_jpeg(
    const uint8_t* y_plane,
    int32_t y_bytes_per_row,
    const uint8_t* u_plane,
    int32_t u_bytes_per_row,
    int32_t u_bytes_per_pixel,
    const uint8_t* v_plane,
    int32_t v_bytes_per_row,
    int32_t v_bytes_per_pixel,
    int32_t width,
    int32_t height,
    int32_t max_dimension,
    int32_t quality,
    GhosteyeJpegImage* out_image);

FFI_PLUGIN_EXPORT void ghosteye_jpeg_free_buffer(uint8_t* buffer);
