function [ fn ] = getBatchWrapper_imgs(opts, numThreads, trainopts)
fn = @(imdb,batch, moreopts) getBatch(imdb,batch,opts,numThreads, trainopts, moreopts) ;

end

% -------------------------------------------------------------------------
function [im,labels] = getBatch(imdb, batch, opts, numThreads, trainopts, moreopts)
% -------------------------------------------------------------------------
opts.nFrames = imdb.images.nFrames(batch);
images = cell(1,numel(opts.nFrames));
labels = imdb.images.label(batch) ;
for k = 1:numel(opts.nFrames)
  images{k}  = strcat([imdb.images.name{batch(k)} filesep], images{k} ) ;
end
if ~isempty(moreopts) || nargin < 6
  for f = fieldnames(moreopts)'
    f = char(f) ;
    trainopts.(f) = moreopts.(f);
  end
end


opts.nFramesPerVid = trainopts.nFramesPerVid;
opts.numAugments = trainopts.numAugments;
opts.frameSample = trainopts.frameSample;
opts.augmentation =  trainopts.augmentation;
if isfield(trainopts, 'temporalStride')
  opts.temporalStride =  trainopts.temporalStride(randi(numel(trainopts.temporalStride))) ; % shuffle;
end
if isfield(trainopts, 'keepFramesDim')
  keepFramesDim = trainopts.keepFramesDim;
else
  keepFramesDim = false;
end
if isfield(trainopts, 'cheapResize')
  opts.cheapResize =  trainopts.cheapResize;
end
if isfield(trainopts, 'prefetch')
    opts.prefetch = trainopts.prefetch;
end
if isfield(trainopts, 'frameList')
    opts.frameList = trainopts.frameList;
end

im = cnn_get_frame_batch(images, opts, ...
                            'numThreads', numThreads, ...
                            'augmentation', opts.augmentation , ...
                          'imageDir', imdb.imageDir) ;
                        
if iscell(im), return; end

labels = imdb.images.label(batch) ;

if nargout == 1 % to work with dag code
  if ndims(im) > 4 && ~keepFramesDim
    sz = size(im);
    nFrames = sz(5:end);
    im = permute(im, [1 2 3 5 4]);
    im = reshape(im, sz(1), sz(2), sz(3), []);
  end
  if size(im,3) > 1
    im = {'input', im(:,:,end-2:end,:,:), 'label', labels, 'input_flow', im(:,:,1:end-3,:,:)} ;
  else
    im = {'input', im, 'label', labels} ;
  end
end

end
