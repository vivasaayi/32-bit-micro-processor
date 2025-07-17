package tabs;

import javax.swing.*;
import java.awt.*;
import util.AppState;

public class VcdTab extends BaseTab {
    private JTextArea vcdArea;
    
    public VcdTab(AppState appState, JFrame parentFrame) {
        super(appState, parentFrame);
    }
    
    @Override
    protected void initializeComponents() {
        vcdArea = new JTextArea();
        vcdArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 11));
    }
    
    @Override
    protected void setupLayout() {
        setLayout(new BorderLayout());
        add(new JScrollPane(vcdArea), BorderLayout.CENTER);
    }
    
    @Override
    public void loadContent(String content) {
        vcdArea.setText(content);
    }
    
    @Override
    public void saveContent() {
        // VCD files are typically read-only
    }
    
    @Override
    public void clearContent() {
        // VCD content can be cleared
    }
}
