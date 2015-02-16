function [message,error_id,whatswrong]=moxunit_util_floats_almost_equal(a,b,f,varargin)
% compare equality of two float arrays up to certain tolerance
%
% [message,error_id,whatswrong]=moxunit_is_almost_equal(a,b[,tol_type,tol,floor_tol,msg])
%
% Inputs:
%   a           float array
%   b           float array
%   f           function handle to a function that takes one vector input
%               and returns a scalar output.
%   tol_type    'relative' or 'absolute' (default: 'relative')
%   tol         tolerance       } default: sqrt(eps) if a is double,
%   floor_tol   floor_tolerance } sqrt(eps('single')) otherwise)
%   msg         optional custom message
%
% Output:
%   message     the contents of msg, if provided; empty ('') otherwise
%   id          the empty string ('') if a and b are almost equal,
%               otherwise:
%               'moxunit:notFloat'           a or b is not a float array
%               'moxunit:differentClass      a and b are of different class
%               'moxunit:differentSize'      a and b are of different size
%               'moxunit:differentSparsity'  a is sparse and b is not, or
%                                            vice versa
%               'moxunit:floatsDiffer'       values in a and b are not
%                                            almost equal (see note below)
%   whatswrong  if id is not empty, a human-readible description of the
%               inequality between a and b
%
% Notes:
%   - Typical values for the function handle f are:
%     * @abs:  element-wise comparison
%     * @norm: vector comparison
%   - If tol_type is 'relative', a and b are almost equal if
%
%           all(f(a(:)-b(:))<=tol*max(f(a(:)),f(b(:)))+floor_tol);
%
%   - If tol_type is 'absolute', a and b are almost equal if
%
%           all(f(a(:)-b(:))<=tol);
%
%   - It follows that if any value in a or b is not finite (+Inf, -Inf, or
%     NaN), then a and b are not almost equal.
%   - This is a helper function for assertElementsAlmostEqual and
%     assertVectorsAlmostEqual
%
% See also: assertElementsAlmostEqual, assertVectorsAlmostEqual
%
% NNO Jan 2014


    [message,tol_type,tol,floor_tol]=get_params(a,varargin{:});

    if ~isfloat(a)
        whatswrong='first input is not float';
        error_id='moxunit:notFloat';
    elseif ~isnumeric(b)
        whatswrong='second input is not float';
        error_id='moxunit:notFloat';
    else
        [error_id,whatswrong]=moxunit_util_elements_compatible(a,b);
    end

    if ~isempty(error_id)
        return;
    end


    switch tol_type
        case 'relative'
            test_func=@(x,y) all(f(x(:)-y(:))<=...
                                tol*max(f(y(:)),f(x(:)))+floor_tol);
        case 'absolute'
            test_func=@(x,y) all(f(x(:)-y(:))<=tol);

        otherwise
            error('moxunit:illegalParameter',...
                    'unsupported tolerance type %s', tol_type);
    end

    all_equal=(iscomplex(a) && test_func(real(a),real(b)) && ...
                                    test_func(imag(a),imag(b))) ||...
              (isreal(a) && test_func(a,b));

    if ~all_equal
        whatswrong=sprintf(['inputs are not equal within '...
                                '%s tolerance %d'],tol_type,tol);
        error_id='moxunit:floatsNotAlmostEqual';
    end


function [message,tol_type,tol,floor_tol]=get_params(a,varargin)
    n=numel(varargin);

    tol_type=[];
    tol=[];
    floor_tol=[];
    message='';

    for k=1:n
        arg=varargin{k};
        if ischar(arg)
            if (strcmp(arg,'relative') || strcmp(arg,'absolute')) && ...
                    isnumeric(tol_type)

                tol_type=arg;
                continue;

            elseif k==n && isempty(message)
                message=arg;
                continue
            end

        elseif isscalar(arg)
            if isempty(tol)
                tol=arg;
                continue
            elseif isempty(floor_tol)
                floor_tol=arg;
                continue
            end
        end

        error('moxunit:illegalParameter',...
                    'Illegal argument at position %d', k);
    end

    % set defaults for values that were not set
    if isempty(floor_tol)
        switch class(a)
            case 'double'
                default_tol=sqrt(eps);
            case 'single'
                default_tol=sqrt(eps('single'));
            otherwise
                % set to illegal value; it is never used because
                % the calling function raises an error before tol or
                % floor_tol are used
                default_tol=NaN;
        end

        floor_tol=default_tol;
    end

    if isempty(tol)
        tol=default_tol;
    end

    if isempty(tol_type)
        tol_type='relative';
    end

