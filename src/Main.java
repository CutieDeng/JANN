import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Objects;
import java.util.Random;
import java.util.Scanner;
import java.util.function.Function;

public class Main {

    public static Function<Float, Float> sigmoid = (x) -> (float) (1 / (1 + Math.exp(-x))); 
    public static Function<Float, Float> relu = (x) -> {
        if (x < 0) {
            return 0f; 
        } else {
            return x; 
        } 
    }; 
    public static Function<Float, Float> reluPrime = (x) -> {
        if (x < 0) {
            return 0f; 
        } else {
            return 1f; 
        } 
    }; 
    public static Function<Float, Float> sigmoidPrime = (x) -> (float) (Math.exp(-x) / Math.pow(1 + Math.exp(-x), 2)); 

    public static Matrix loss(Matrix output, Matrix tags) {
        if (output.row != tags.row || output.col != tags.col) {
            throw new IllegalArgumentException(); 
        } 
        Matrix m = new Matrix(output.row, 1); 
        for (int i = 0; i < output.row; i++) {
            float tmp = 0; 
            for (int j = 0; j < output.col; j++) {
                tmp += Math.pow(output.get(i, j) - tags.get(i, j), 2);  
            } 
            m.set(i, 0, tmp); 
        } 
        return m; 
    }

    public static class Backward {
        public Matrix nn1Change; 
        public Matrix nn2Change; 
        public Matrix nn3Change; 
        public Matrix b1Change; 
        public Matrix b2Change; 
        public Matrix b3Change; 
        public Matrix lossMatrix; 
    }

    public static class Structure {
        public Matrix nn1; 
        public Matrix nn2; 
        public Matrix nn3; 
    }

    public static Backward backward(Matrixs input, Structure struct, Matrix tags) {
        // check all matrixes ~ 
        {
            input.input.check(); 
            input.result1.check(); 
            input.result2.check(); 
            input.result3.check(); 
            tags.check(); 
            struct.nn1.check(); 
            struct.nn2.check(); 
            struct.nn3.check(); 
            input.multiply1.check(); 
            input.multiply2.check(); 
            input.multiply3.check(); 
        }
        float scalar = 1e-6f; 
        // test the size of tags & input 
        if (input.result3.row != tags.row || input.result3.col != tags.col) {
            throw new IllegalArgumentException(); 
        } 
        Backward backward = new Backward(); 
        Matrix result_delta ; 
        {
            result_delta = input.result3.clone(); 
            result_delta.minus(tags); 
            var tmp = result_delta.transpose(); 
            backward.lossMatrix = result_delta.multiply(tmp); 
        }
        backward.nn3Change = input.result2.transpose().multiply(result_delta); 
        backward.nn3Change.scalar_multiply( (float ) ( 1. / tags.row ) ); 
        {
            var tmp = struct.nn3.clone(); 
            tmp.scalar_multiply(scalar); 
            backward.nn3Change.add(tmp); 
        }
        backward.b3Change = result_delta.col_average(); 
        {
            // var tmp = struct.nn3.transpose().multiply(result_delta); 
            var tmp = result_delta.multiply( struct.nn3.transpose() ); 
            result_delta = new Matrix(input.result2.row, input.result2.col); 
            for (int i = 0; i < input.result2.row; i++) {
                for (int j = 0; j < input.result2.col; j++) {
                    result_delta.set(i, j, reluPrime.apply(input.result2.get(i, j)) * tmp.get(i, j)); 
                } 
            } 
        } 
        backward.nn2Change = input.result1.transpose().multiply(result_delta); 
        {
            var tmp = struct.nn2.clone(); 
            tmp.scalar_multiply(scalar); 
            backward.nn2Change.add(tmp);
        }
        backward.nn2Change.scalar_multiply( (float ) ( 1. / tags.row ) ); 
        backward.b2Change = result_delta.col_average(); 
        {
            // var tmp = struct.nn2.transpose().multiply(result_delta); 
            var tmp = result_delta.multiply( struct.nn2.transpose() ); 
            result_delta = new Matrix(input.result1.row, input.result1.col); 
            for (int i = 0; i < input.result1.row; i++) {
                for (int j = 0; j < input.result1.col; j++) {
                    result_delta.set(i, j, reluPrime.apply(input.result1.get(i, j)) * tmp.get(i, j)); 
                } 
            } 
        } 
        backward.nn1Change = input.input.transpose().multiply(result_delta); 
        backward.nn1Change.scalar_multiply( (float ) ( 1. / tags.row ) ); 
        {
            var tmp = struct.nn1.clone(); 
            tmp.scalar_multiply(scalar); 
            backward.nn1Change.add(tmp); 
        }
        backward.b1Change = result_delta.col_average(); 
        return backward; 
    }

    public static class Matrixs {
        public Matrix input; 
        public Matrix multiply1; 
        public Matrix result1; 
        public Matrix multiply2; 
        public Matrix result2; 
        public Matrix multiply3; 
        public Matrix result3; 
    }

    public static void main(String[] args) {

        long start_time = System.currentTimeMillis(); 

        int INPUT_LAYER = 784; 
        int NUMBER_LAYER1 = 300; 
        int NUMBER_LAYER2 = 100; 
        int NUMBER_LAYER3 = 10; 

        // assert all matrix here are valid & not null 
        var input = input(); 

        var read_time = System.currentTimeMillis(); 
        System.out.printf("read time: %d ms \n", read_time - start_time); 

        var tags = input2(); 
        
        var read_time2 = System.currentTimeMillis(); 
        System.out.printf("read time2: %d ms \n", read_time2 - read_time); 

        Objects.requireNonNull(input); 
        var nn1 = random(INPUT_LAYER, NUMBER_LAYER1); 
        var nn2 = random(NUMBER_LAYER1, NUMBER_LAYER2); 
        var nn3 = random(NUMBER_LAYER2, NUMBER_LAYER3); 
        var b1 = random(1, NUMBER_LAYER1); 
        var b2 = random(1, NUMBER_LAYER2); 
        var b3 = random(1, NUMBER_LAYER3); 

        var init_time = System.currentTimeMillis(); 
        System.out.printf("init time: %d ms \n", init_time - read_time2); 
    
        long index = 1; 
        float lambda = 0.0001f; 
        var structure = new Structure(); 
        structure.nn1 = nn1; 
        structure.nn2 = nn2; 
        structure.nn3 = nn3; 
        while (true) {
            var matrixs = forward(input, nn1, nn2, nn3, b1, b2, b3); 
            var backward = backward(matrixs, structure, tags);         
            var loss_sum = backward.lossMatrix.sum(); 
            System.out.printf("%d round\n", index);
            index ++; 
            System.out.printf("loss: %f\n", loss_sum); 
            
            var end_time = System.currentTimeMillis(); 
            System.out.printf("time: %d ms \n", end_time - init_time); 

            if (loss_sum < 0.01f) {
                System.out.println("success"); 
                break; 
            } 
            {
                backward.nn1Change.scalar_multiply(lambda); 
                backward.nn2Change.scalar_multiply(lambda); 
                backward.nn3Change.scalar_multiply(lambda); 
                backward.b1Change.scalar_multiply(lambda); 
                backward.b2Change.scalar_multiply(lambda); 
                backward.b3Change.scalar_multiply(lambda); 
            }
            nn1.minus(backward.nn1Change); 
            nn2.minus(backward.nn2Change); 
            nn3.minus(backward.nn3Change);
            b1.minus(backward.b1Change); 
            b2.minus(backward.b2Change); 
            b3.minus(backward.b3Change); 

            // nn1.add(backward.nn1Change); 
            // nn2.add(backward.nn2Change); 
            // nn3.add(backward.nn3Change);
            // b1.add(backward.b1Change); 
            // b2.add(backward.b2Change); 
            // b3.add(backward.b3Change); 
        }
    }
    
    public static Matrix input2() {
        try (// data : data/label.txt 
        var scanner = new Scanner(new FileInputStream("data/label.txt"))) {
            var list = new ArrayList<float[]>(); 
            while (true) {
                if (!scanner.hasNextLine()) {
                    break; 
                }
                var line = scanner.nextLine(); 
                var split = line.split(" "); 
                var array = new float[split.length]; 
                for (int i = 0; i < split.length; i++) {
                    array[i] = Float.parseFloat(split[i]); 
                }
                list.add(array);  
            }
            var matrix = new Matrix(list.size(), list.get(0).length); 
            for (int i = 0; i < list.size(); i++) {
                for (int j = 0; j < list.get(i).length; j++) {
                    matrix.set(i, j, list.get(i)[j]); 
                } 
            } 
            return matrix; 
        } catch (FileNotFoundException e) {
            e.printStackTrace();
            throw new RuntimeException(e); 
        } 
    }

    public static Matrixs forward(Matrix input, Matrix nn1, Matrix nn2, Matrix nn3, Matrix b1, Matrix b2, Matrix b3) {
        {
            // check all matrix 
            input.check(); 
            nn1.check(); 
            nn2.check(); 
            nn3.check(); 
            b1.check(); 
            b2.check(); 
            b3.check(); 
        }
        Matrixs matrixs = new Matrixs(); 
        matrixs.input = input; 
        matrixs.multiply1 = input.multiply(nn1); 
        matrixs.multiply1.add(b1.extension_repeated_rows(matrixs.multiply1.row)); 
        var tmp = matrixs.multiply1.clone(); 
        tmp.apply(relu); 
        matrixs.result1 = tmp; 
        matrixs.multiply2 = matrixs.result1.multiply(nn2); 
        matrixs.multiply2.add(b2.extension_repeated_rows(matrixs.multiply2.row)); 
        tmp = matrixs.multiply2.clone(); 
        tmp.apply(relu); 
        matrixs.result2 = tmp; 
        matrixs.multiply3 = matrixs.result2.multiply(nn3); 
        matrixs.multiply3.add(b3.extension_repeated_rows(matrixs.multiply3.row)); 
        tmp = matrixs.multiply3.clone(); 
        // softmax algo 
        // tmp.apply(a -> (float ) Math.exp(a));
        // sum each row 
        for (int i = 0; i < tmp.row; i++) {
            float sum = 0; 
            for (int j = 0; j < tmp.col; j++) {
                sum += tmp.get(i, j); 
            } 
            // check sum 
            if (sum == 0) {
                System.err.printf("matrix row = %d, col = %d", tmp.row, tmp.col); 
                throw new RuntimeException("sum is zero"); 
            } 
            if (sum == Float.POSITIVE_INFINITY || sum == Float.NEGATIVE_INFINITY) {
                throw new RuntimeException("sum is infinity"); 
            } 
            // NaN 
            if (sum != sum) {
                throw new RuntimeException("sum is NaN"); 
            } 
            for (int j = 0; j < tmp.col; j++) {
                tmp.set(i, j, tmp.get(i, j) / sum); 
            } 
        } 
        matrixs.result3 = tmp; 
        return matrixs;  
    } 

    // 读入数据 ～ 值得注意，这里的输入是一个矩阵，其中每一行都是一组有效的数据条目 
    public static Matrix input() {
        try (// read data from 'data/train.txt' 
        var inputStream = new Scanner(new FileInputStream("data/train.txt"))) {
            // var data = new ArrayList<float[]>(); 
            // var buffer = new byte[1024]; 
            // var offset = 0; 
            // var length = 0; 
            // while ((length = inputStream.read(buffer, offset, buffer.length - offset)) != -1) {
            //     offset += length; 
            //     if (offset == buffer.length) {
            //         var newBuffer = new byte[buffer.length * 2]; 
            //         System.arraycopy(buffer, 0, newBuffer, 0, buffer.length); 
            //         buffer = newBuffer; 
            //     } 
            // } 
            // var str = new String(buffer, 0, offset); 
            // var lines = str.split(" |\n"); 
            var list = new ArrayList<float[]>(); 
            while (true) {
                float[] data = new float[784]; 
                for (int i = 0; i < 784; ++i) {
                    data[i] = inputStream.nextFloat();  
                }
                list.add(data); 
                if (!inputStream.hasNext()) {
                    break; 
                } 
            }
            var matrix = new Matrix(list.size(), 784); 
            for (int i = 0; i < list.size(); i++) {
                for (int j = 0; j < 784; j++) {
                    matrix.set(i, j, list.get(i)[j]); 
                } 
            } 
            return matrix; 
        } catch (IOException e) {
            e.printStackTrace();
            throw new RuntimeException(e); 
        } 
    }

    public static Matrix random(int row, int col) {
        Matrix m = new Matrix(row, col); 
        // norma distribution 
        var random = new Random(); 
        m.init((i, j) -> (float) random.nextGaussian() );
        return m; 
    } 

}