
#' TODO
#' create a list of enfuse options , algo_01, algo_02,...
#' merge the slabs with each of these algorithms
#' The different algo can be added with an unlimitted number at the end of the general options
#' 
#' create an all option to merge all pictures within the directory and all subdirectories
#' 
#' create a "small" option that will create small sized version of all pictures
#' copy them into a directory than apply the code on these small sized pictures
#' in order to have a quick check 


setwd("/home/gilles/stats/Rprojects/201412_stacking/photos")


a <- Sys.time()


#' List the jpg or tif pictures in the working directory
pics <- list.files( pattern = "\\.(jpeg|jpg|tiff|tif)$", ignore.case = TRUE)

i <- pics[2]

#' Use imagemagik to convert the jpg pictures into tif

jpg <- pics[grep(x = pics, pattern = "\\.(jpg|jpeg)$", ignore.case = TRUE)]

for (i in jpg) {
    system(paste0("convert -rotate 0 -compress none ", i, " z_", i, ".tif"))
}

#' Align the images
start <- Sys.time()

system("align_image_stack -v -m -s 2 -a aligned_ *.tif", show.output.on.console = TRUE)

end <- Sys.time()
end-start

#' Remove the tif files previously created
file.remove(paste0("z_", jpg, ".tif"))

#' Change the temp files location to the curent directory 
#' (to avoid problems of disk space at the normal temp location)
system("export TMPDIR=./")
    



#' create a list of aligned pictures names for each slab
#' 
aligned <- list.files(pattern ="^aligned_.*\\.tif$")

slab_size = 5
slab_overlap = 1

if(slab_overlap >= slab_size) {stop("slab_overlap must be < slab_size")}

pr <- 1:slab_size
slabs <- list(aligned[pr])

while(pr[slab_size] <= length(aligned)) {
    pr <- (pr[length(pr) - slab_overlap] + 1) : (pr[length(pr) - slab_overlap] + slab_size)
    slabs <- c(slabs,list(aligned[pr]))
}

#' Remove the NA values from the last slab
slabs[[length(slabs)]] <- slabs[[length(slabs)]][!is.na(slabs[[length(slabs)]])]

#' Remove the last slab if it contains only pictures already present in the previous slab
if(length(slabs[[length(slabs)]]) == slab_overlap) {
    slabs <- slabs[[-length(slabs)]]
}

# slabs


#' Create the slabs
enfuse_opts <- paste("--verbose=6 -m 400",
                     "--exposure-weight=0.001",
                     "--saturation-weight=0.001",
                     "--contrast-weight=1",
                     "--hard-mask",
                     "--contrast-window-size=5", sep = " ")

for(i in 1:length(slabs)) {
    system(paste("enfuse", enfuse_opts,
                 paste0("-o slab_", sprintf("%04.0f", i), ".tif"),
                 do.call(paste, as.list(slabs[[i]]))), 
           show.output.on.console = TRUE)
}




#' Merge the slabs with a basic contrast window algorithm
nr <- length(slabs)

enfuse_opts <- paste("--verbose=6 -m 400",
                     "--exposure-weight=0.001",
                     "--saturation-weight=0.001",
                     "--contrast-weight=1",
                     "--hard-mask",
                     "--contrast-window-size=5", sep = " ")

system(paste("enfuse", enfuse_opts,
             paste0("-o final_", nr, "slabs.tif"),
             "slab_*.tif", sep = " "), show.output.on.console = TRUE)



#' Merge the slabs with a Laplacian algorithm
enfuse_opts <- paste("--verbose=6 -m 400",
                     "--exposure-weight=0",
                     "--saturation-weight=0",
                     "--contrast-weight=1",
                     "--hard-mask",
                     "--contrast-window-size=5"
                     "--contrast-edge-scale=0.3", 
                     "--contrast-min-curvature=0.5%", sep = " ")

system(paste("enfuse", enfuse_opts,
             paste0("-o final_laplacian_", nr, "slabs.tif"),
             "slab_*.tif", sep = " "), show.output.on.console = TRUE)


#' Merge the aligned pictures without slabbing
start <- Sys.time()

enfuse_opts <- paste("--verbose=6 -m 400",
                     "--exposure-weight=0.001",
                     "--saturation-weight=0.001",
                     "--contrast-weight=1",
                     "--hard-mask",
                     "--contrast-window-size=5", sep = " ")

system(paste("enfuse", enfuse_opts,
             "-o final_.tif",
             "aligned_*.tif", sep = " "), show.output.on.console = TRUE)

end <- Sys.time()
end-start


z <- Sys.time()
z - a

# file.remove(list.files(pattern ="^aligned_.*\\.tif$"))








