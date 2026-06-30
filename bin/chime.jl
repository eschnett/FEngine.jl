using RadioTelescopeFEngine

filename = "/scratch/eschnett/voltage_chime.h5"

T = Float64

adc_frequency = 1.6e+9     # [Hz]
pfb_nsamples = 4096

# Noise gets de-amplified by the FFT, so we choose a higher amplitude
noise = Noise{T}(sqrt(1.0 * pfb_nsamples))

# MonochromaticSource(f, A, angle_x, angle_y)
Δf = adc_frequency / pfb_nsamples
sources = [
#    MonochromaticSource{T}(1025 * Δf, (1.0, 0.0), 0.0, 0.0),
#    MonochromaticSource{T}(2048 * Δf, (1.0, 0.0), 0.0, 0.0),
    MonochromaticSource{T}(800e6 - (800e6-400e6)/1024. * 717, (8.0, 0.0), 0.523598775598299, 2*0.00698131700797732)
]

frb_sources = FRBSource{T}[]

# dish layout according to the CHIME overview paper
# (https://doi.org/10.3847/1538-4365/ac6fd9) table 2. Note that 22.0 = 20+2
# (cylinder with + spacing)
dishgrid = DishGrid{T}(22.0, 0.3048)
dishes = Dish[]
for x in 0:3, y in 0:255
    push!(dishes, Dish(x, y))
end

adc = ADC{T}(0, inv(adc_frequency))
# translate from CHIMEs frequency id convention f_MHz = 800 - i/1024 * (800 - 400)
# with 0 <= i < 1024, so 800Mhz -> i==0. While here f = i * 800/2048, so 800Mhz -> i=2048
freq_ids_CHIME = collect(0:1023)
freq_ids = Int64[]
for id in freq_ids_CHIME
  push!(freq_ids, 2048 - id)
end
pfb = PFB(4, pfb_nsamples, freq_ids) # 400 MHz ... 800 MHz

buffersize = 16384
ntimes = 25 * buffersize        # approx 1 sec

fengine(filename, noise, sources, frb_sources, dishgrid, dishes, adc, pfb, ntimes, buffersize, freq_ids_CHIME)

# time h5repack --layout='voltage:CHUNK=4096x1x2x1024' --filter='voltage:GZIP=9' voltage_chime.h5 voltage_chime_compressed.h5
