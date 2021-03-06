

#include "HSigmoid.hpp"

typedef TRTInfer::halfloat halfloat;

template<typename _T>
__global__ void HSigmoidKernel(_T* input, _T* output, int edge);


template<>
__global__ void HSigmoidKernel(float* input, float* output, int edge) {

    KERNEL_POSITION;
    float x = input[position];
    float a = x + 3;
    a = a < 0 ? 0 : (a >= 6 ? 6 : a);
	output[position] = a / 6;
}

template<>
__global__ void HSigmoidKernel(halfloat* input, halfloat* output, int edge) {

	KERNEL_POSITION;

    halfloat _six = 6.0f;
	halfloat x = input[position];
    halfloat a = x + halfloat(3.0f);
    halfloat _zero = 0.0f;
    a = a < _zero ? _zero : (a >= _six ? _six : a);
	output[position] = a / _six;
}

void HSigmoidConfig::init(){
    //INFO("init HSigmoid config: %s", info_.c_str());
    //INFO("weights = %d", this->weights_.size());
}

nvinfer1::Dims HSigmoid::outputDims(int index, const nvinfer1::Dims* inputDims, int nbInputDims) {
	return inputDims[0];
}

std::shared_ptr<LayerConfig> HSigmoid::config(const std::string& layerName) {
	auto cfg = std::shared_ptr<LayerConfig>(new HSigmoidConfig());

	//定义我们这个插件支持half和float格式
	cfg->supportDataType_ = {nvinfer1::DataType::kHALF, nvinfer1::DataType::kFLOAT};
	//cfg->supportDataType_ = {nvinfer1::DataType::kHALF};
	return cfg;
}

int HSigmoid::enqueue(const std::vector<GTensor>& inputs, std::vector<GTensor>& outputs, const std::vector<GTensor>& weights, void* workspace, cudaStream_t stream) {

	int count = inputs[0].count();
	auto grid = gridDims(count);
	auto block = blockDims(count);

	if (config_->configDataType_ == TRTInfer::DataType::dtFloat) {
		HSigmoidKernel <<<grid, block >>> (inputs[0].ptr<float>(), outputs[0].ptr<float>(), count);
	}
	else if (config_->configDataType_ == TRTInfer::DataType::dtHalfloat) {
		HSigmoidKernel <<<grid, block>>> (inputs[0].ptr<halfloat>(), outputs[0].ptr<halfloat>(), count);
	}
	return 0;
}

RegisterPlugin(HSigmoid);