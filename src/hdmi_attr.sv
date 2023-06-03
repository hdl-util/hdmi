// Package for representing/manipulating HDMI stream attributes
package hdmi_attr;

// Basic video attributes
typedef struct {
    // Width/height of HDMI frame, including blanking periods
    int frame_width;
    int frame_height;
    // Width/height of screen (active video)
    int screen_width;
    int screen_height;
    // Start of hsync pulse in pixel clock cycles after start of horizontal
    // blanking
    int hsync_pulse_start;
    // Size of hsync pulse in pixel clock cycles
    int hsync_pulse_size;
    // Start of vsync pulse in scanlines after start of vertical blanking. The
    // pulse is always aligned with the start of hsync on the indicated
    // scanline (as required by CEA-861-D), so the actual start is
    // (frame_width * vsync_pulse_start + hsync_pulse_start) pixel clock
    // cycles after the last active pixel.
    int vsync_pulse_start;
    // Size of vsync pulse in scanlines
    int vsync_pulse_size;
    // Sync pulses are negative-going if true
    logic invert;
    // Base pixel clock rate in Hz.  Can be modified when using 59.94/29.97
    // vertical refresh rate.
    real base_pixel_clock;
} video_attr_t;

// Get video attributes for supported CEA-861-D video ID code
function video_attr_t video_attr_for_id(int code);
    case (code)
    1: return '{
        frame_width: 800,
        frame_height: 525,
        screen_width: 640,
        screen_height: 480,
        hsync_pulse_start: 16,
        hsync_pulse_size: 96,
        vsync_pulse_start: 10,
        vsync_pulse_size: 2,
        invert: 1,
        base_pixel_clock: 25.2E6
    };
    2, 3: return '{
        frame_width: 858,
        frame_height: 525,
        screen_width: 720,
        screen_height: 480,
        hsync_pulse_start: 16,
        hsync_pulse_size: 62,
        vsync_pulse_start: 9,
        vsync_pulse_size: 6,
        invert: 1,
        base_pixel_clock: 27.027E6
    };
    4: return '{
        frame_width: 1650,
        frame_height: 750,
        screen_width: 1280,
        screen_height: 720,
        hsync_pulse_start: 110,
        hsync_pulse_size: 40,
        vsync_pulse_start: 5,
        vsync_pulse_size: 5,
        invert: 0,
        base_pixel_clock: 74.25E6
    };
    16: return '{
        frame_width: 2200,
        frame_height: 1125,
        screen_width: 1920,
        screen_height: 1080,
        hsync_pulse_start: 88,
        hsync_pulse_size: 44,
        vsync_pulse_start: 4,
        vsync_pulse_size: 5,
        invert: 0,
        base_pixel_clock: 148.5E6
    };
    17, 18: return '{
        frame_width: 864,
        frame_height: 625,
        screen_width: 720,
        screen_height: 576,
        hsync_pulse_start: 12,
        hsync_pulse_size: 64,
        vsync_pulse_start: 5,
        vsync_pulse_size: 5,
        invert: 1,
        base_pixel_clock: 27E6
    };
    19: return '{
        frame_width: 1980,
        frame_height: 750,
        screen_width: 1280,
        screen_height: 720,
        hsync_pulse_start: 440,
        hsync_pulse_size: 40,
        vsync_pulse_start: 5,
        vsync_pulse_size: 5,
        invert: 0,
        base_pixel_clock: 74.25E6
    };
    34: return '{
        frame_width: 2200,
        frame_height: 1125,
        screen_width: 1920,
        screen_height: 1080,
        hsync_pulse_start: 88,
        hsync_pulse_size: 44,
        vsync_pulse_start: 4,
        vsync_pulse_size: 5,
        invert: 0,
        base_pixel_clock: 74.25E6
    };
    95, 105, 97, 107: return '{
        frame_width: 4400,
        frame_height: 2250,
        screen_width: 3840,
        screen_height: 2160,
        hsync_pulse_start: 176,
        hsync_pulse_size: 88,
        vsync_pulse_start: 8,
        vsync_pulse_size: 10,
        invert: 0,
        base_pixel_clock: 595E6
    };
    endcase
endfunction

endpackage
