import java.util.function.BiFunction;
import java.util.function.Function;

public class Matrix {
    private final float[] content; 
    public final int row, col; 
    public Matrix(int row, int col) {
        if (row <= 0 || col <= 0) {
            throw new IllegalArgumentException(); 
        } 
        this.row = row; 
        this.col = col; 
        this.content = new float[(int) (row * col)]; 
    } 
    public float get(int row, int col) {
        if (row < 0 || row >= this.row || col < 0 || col >= this.col) {
            throw new IndexOutOfBoundsException(); 
        } 
        return this.content[row * this.col + col]; 
    } 
    public void set(int row, int col, float value) {
        if (row < 0 || row >= this.row || col < 0 || col >= this.col) {
            throw new IndexOutOfBoundsException(); 
        } 
        this.content[row * this.col + col] = value; 
    } 
    public void init(float value) {
        for (int i = 0; i < this.content.length; i++) {
            this.content[i] = value; 
        } 
    } 
    public void init(float[] values) {
        if (values.length != this.content.length) {
            throw new IllegalArgumentException(); 
        } 
        for (int i = 0; i < this.content.length; i++) {
            this.content[i] = values[i]; 
        } 
    } 
    public void init( BiFunction<Integer, Integer, Float> f) {
        for (int i = 0; i < this.row; i++) {
            for (int j = 0; j < this.col; j++) {
                this.content[i * this.col + j] = f.apply(i, j); 
            } 
        } 
    } 
    // clone 
    public Matrix clone() {
        Matrix m = new Matrix(this.row, this.col); 
        for (int i = 0; i < this.content.length; i++) {
            m.content[i] = this.content[i]; 
        } 
        return m; 
    } 
    // add on 
    public void add(Matrix m) {
        if (this.row != m.row || this.col != m.col) {
            // more details : 
            System.err.printf( 
                "Matrix.add: this.row = %d, this.col = %d, m.row = %d, m.col = %d\n", 
                this.row, this.col, m.row, m.col ); 
            throw new IllegalArgumentException(); 
        } 
        for (int i = 0; i < this.content.length; i++) {
            this.content[i] += m.content[i]; 
            // check NAN 
            // if (Float.isNaN(this.content[i])) {
            //     System.err.printf("Matrix.add: this.content[%d] = %f, m.content[%d] = %f\n", 
            //         i, this.content[i], i, m.content[i]); 
            //     throw new IllegalArgumentException(); 
            // } 
        } 
    } 
    // minus on 
    public void minus(Matrix m) {
        if (this.row != m.row || this.col != m.col) {
            throw new IllegalArgumentException(); 
        } 
        for (int i = 0; i < this.content.length; i++) {
            this.content[i] -= m.content[i]; 
            // check NaN 
            // if (Float.isNaN(this.content[i])) {
            //     System.err.printf("Matrix.minus: this.content[%d] = %f, m.content[%d] = %f\n", 
            //         i, this.content[i], i, m.content[i]); 
            //     throw new IllegalArgumentException(); 
            // } 
        } 
    } 
    // multiply on 
    public void scalar_multiply(float value) {
        for (int i = 0; i < this.content.length; i++) {
            this.content[i] *= value; 
        } 
    } 
    public void scalar_multiply(Matrix other) {
        if (this.row != other.row || this.col != other.col) {
            throw new IllegalArgumentException(); 
        } 
        for (int i = 0; i < this.content.length; i++) {
            this.content[i] *= other.content[i]; 
        }  
    }
    // multiply 
    public Matrix multiply(Matrix other) {
        if (this.col != other.row) {
            System.err.printf(
                "Matrix.multiply: this.row = %d, this.col = %d, other.row = %d, other.col = %d\n", 
                this.row, this.col, other.row, other.col); 
            throw new IllegalArgumentException(); 
        } 
        Matrix m = new Matrix(this.row, other.col); 
        for (int i = 0; i < this.row; i++) {
            for (int j = 0; j < other.col; j++) {
                float sum = 0; 
                for (int k = 0; k < this.col; k++) {
                    sum += this.get(i, k) * other.get(k, j); 
                } 
                // check sum is NaN 
                if (Float.isNaN(sum)) { 
                    System.err.printf("Multiply result on (%d, %d) is NaN\n", i, j); 
                    throw new IllegalArgumentException(); 
                } 
                m.set(i, j, sum); 
            } 
        } 
        return m; 
    }
    public Matrix transpose() {
        Matrix m = new Matrix(this.col, this.row); 
        for (int i = 0; i < this.row; i++) {
            for (int j = 0; j < this.col; j++) {
                m.set(j, i, this.get(i, j)); 
            } 
        } 
        return m;  
    }
    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder(); 
        for (int i = 0; i < this.row; i++) {
            for (int j = 0; j < this.col; j++) {
                sb.append(this.get(i, j)); 
                sb.append(" "); 
            } 
            sb.append("\n"); 
        }     
        return sb.toString(); 
    }
    public void map(Function<Float, Float> f) {
        for (int i = 0; i < this.content.length; i++) {
            float tmp = f.apply(this.content[i]); 
            // check tmp is NaN 
            if (Float.isNaN(tmp)) {
                System.err.printf("Matrix.map: this.content[%d] = %f\n", i, this.content[i]); 
                throw new IllegalArgumentException(); 
            }  
            this.content[i] = tmp; 
        } 
    }
    public void apply(Function<Float, Float> f) {
        map(f); 
    } 
    public Matrix extension_repeated_rows(int rows) {
        // assert it is a row vector ~ 
        if (this.row != 1) {
            throw new IllegalArgumentException(); 
        } 
        Matrix m = new Matrix(rows, col); 
        for (int j = 0; j < m.row; j++) {
            for (int i = 0; i < m.col; i++) {
                m.set(j, i, this.get(0, i)); 
            } 
        } 
        return m; 
    }
    public Matrix col_average() {
        Matrix m = new Matrix(1, this.col); 
        for (int i = 0; i < this.col; i++) {
            float sum = 0; 
            for (int j = 0; j < this.row; j++) {
                sum += this.get(j, i); 
            } 
            m.set(0, i, sum / this.row); 
        } 
        return m;  
    }
    public static Matrix averages(Matrix ...matrixs) {
        Matrix m = new Matrix(matrixs[0].row, matrixs[0].col); 
        for (Matrix matrix : matrixs) {
            m.add(matrix); 
        } 
        m.scalar_multiply(1.0f / (matrixs.length)); 
        return m;  
    }
    public float sum() {
        float sum = 0; 
        for (int i = 0; i < this.content.length; i++) {
            sum += this.content[i]; 
        } 
        return sum;  
    }
    public void check() {
        for (int i = 0; i < this.content.length; i++) {
            if (Float.isNaN(this.content[i])) {
                System.err.printf("Matrix.check: this.content[%d] = %f\n", i, this.content[i]); 
                throw new IllegalArgumentException(); 
            } 
        } 
    }
}
